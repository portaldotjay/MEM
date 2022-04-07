<#
.SYNOPSIS
    Gets Windows 11 Readiness status of devices enrolled in Intune.
.DESCRIPTION
    This command will return whether or not devices will support Windows 11 based on their hardware. Status results include RAM Check Failed, Storage Check Failed, Processor Check Failed, TPM Check Failed, Secure Boot Check Failed, Any Checks Failed, Capable, Unknown. Results can be exported to CSV. 
.PARAMETER Status
    Return the devices that match the readiness status. Valid inputs are "ramCheckFailed", "storageCheckFailed", "processorCoreCountCheckFailed", "processorSpeedCheckFailed", "tpmCheckFailed", "secureBootCheckFailed", "processorFamilyCheckFailed", "processor64BitCheckFailed", "osCheckFailed", "notCapable", "capable", "unknown", "upgraded", and "all".
.PARAMETER ExportCSV
    Exports the returned results to the path specified. Path and file name with extension .csv must be used. 
.PARAMETER addToGroup
    Adds devices from the returned results to the group specified. Will also remove devices from the group if not in the returned results. Must use the AAD group ID and devices must be in AAD. 
.EXAMPLE
    PS C:\>Get-Win11ReadinessStatus -Status "ramCheckFailed" -ExportCSV "C:\Win11Readiness\failedRAMResults.csv" -addToGroup "00000000-df80-47ac-a4e6-e01ec30d9f6f"
    Gets all devices that failed the readiness check due to failed RAM check, exports them to a CSV, and adds them to the specified group. 
#>
function Get-Win11ReadinessStatus {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet(
            "ramCheckFailed",
            "storageCheckFailed",
            "processorCoreCountCheckFailed",
            "processorSpeedCheckFailed",
            "tpmCheckFailed",
            "secureBootCheckFailed",
            "processorFamilyCheckFailed",
            "processor64BitCheckFailed",
            "osCheckFailed",
            "notCapable",
            "capable", 
            "unknown",
            "upgraded",
            "all"
        )
        ]
        [string]$Status = "all",
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$ExportCSV,
        [Parameter(Mandatory = $false)]
        [guid]$addToGroup
    )

    ## Initialize some variables
    $failedSplat = @(
        "ramCheckFailed",
        "storageCheckFailed",
        "processorCoreCountCheckFailed",
        "processorSpeedCheckFailed",
        "tpmCheckFailed",
        "secureBootCheckFailed",
        "processorFamilyCheckFailed",
        "processor64BitCheckFailed",
        "osCheckFailed"
    )
    $statusSplat = @(
        "notCapable",
        "capable", 
        "unknown",
        "upgraded"
    )
    $groupId = [string]$addToGroup

    Select-MgProfile -Name 'beta'
    Connect-MgGraph -Scopes "Device.Read.All","DeviceManagementManagedDevices.Read.All","GroupMember.ReadWrite.All" > $null
    $date = Get-Date -Format yyyy-MM-dd-HHmm

    ## Gets devices and their Work from Anywhere metrics
    $requestParams = @{
        Uri     = "/beta/deviceManagement/userExperienceAnalyticsWorkFromAnywhereMetrics/allDevices/metricDevices"
        Method  = "GET"
    }
    $getDevices = Invoke-MgGraphRequest @requestParams -OutputType PSObject
    $devices = @()
    $devices += @($getDevices.value)
    $nextLink = $getDevices.'@odata.nextLink'

    ## Pagination for Get Devices
    while ($getDevices.'@odata.nextLink') {
        $requestParams.Uri = $getDevices.'@odata.nextLink'
        $getDevices = Invoke-MgGraphRequest @requestParams -OutputType PSObject
        $devices += @($getDevices.value)
    }

    ## Filters devices based on -Status parameter
    if ($status -in $failedSplat) {
        $filteredDevices = $devices | where { $_.$status }
    }
    elseif ($status -in $statusSplat) {
        $filteredDevices = $devices | where { $_.upgradeEligibility -eq $status }
    }
    elseif ($status -eq "all") {
        $filteredDevices = $devices
    }

    ## Exports filtered devices to CSV
    if ($PSBoundParameters.ContainsKey('ExportCSV')) {
        $filteredDevices | Export-Csv -LiteralPath $ExportCSV -NoTypeInformation
    }

    ## Gets filtered devices' AAD object ID and adds them to the group selected with -addToGroup
    if ($PSBoundParameters.ContainsKey('addToGroup')) {
        $filteredDevices = $filteredDevices | where { $_.azureAdDeviceId -ne "00000000-0000-0000-0000-000000000000" }
        $filteredDevices | Add-Member -MemberType NoteProperty -Name aadObjectId -Value $null
        $filteredDevices | Add-Member -MemberType NoteProperty -Name requestParamsBody -Value $null
        
        $requestParams = @{
            Method  = "GET"
            Uri     = "/beta/groups/$groupId`?select=displayName"
        }

        $groupName = (Invoke-MgGraphRequest @requestParams).displayName

        Write-Host "Are you sure you want to modify the membership of `"$groupName`"`? (y/n)" -ForegroundColor Yellow
        $confirmation = Read-Host

        if ($confirmation -ne "y") {
            return Write-Host "Canceling group modification." -ForegroundColor Red
        }

        ## Get Current Group Members
        $requestParams.Uri = "https://graph.microsoft.com/beta/groups/$groupId/members?select=id,displayName"
        $getGroupMembers = Invoke-MgGraphRequest @requestParams 
        $nextLink = $getGroupMembers.'@odata.nextLink'
        $groupMembers = @($getGroupMembers.value)
        
        ## Pagination for Current Group Members
        while ($nextLink) {
            $requestParams.Uri = $nextLink
            $getGroupMembers = Invoke-MgGraphRequest @requestParams
            $nextLink = $getGroupMembers.'@odata.nextLink'
            $groupMembers += @($getGroupMembers.value)
        }

        ## Get AAD Object ID of Filtered Devices
        foreach ($filteredDevice in $filteredDevices) {
            $requestParams.Uri = "https://graph.microsoft.com/beta/devices?filter=deviceId eq '$($filteredDevice.azureAdDeviceId)'&select=id"
            $getAadDevice = Invoke-MgGraphRequest @requestParams
            $filteredDevice.aadObjectId = $getAadDevice.value.id
            
            ## Check if Filtered Device is in Group and if not add it. 
            if ($filteredDevice.aadObjectId -in $groupMembers.id) {
                Write-Host "$($filteredDevice.deviceName) already a member."
            }
            else {
                Write-Host "Adding $($filteredDevice.deviceName)."
                $Uri = "https://graph.microsoft.com/beta/groups/$groupId/members/`$ref"
                $body = @{
                    "@odata.id" = "https://graph.microsoft.com/beta/directoryObjects/$($filteredDevice.aadObjectId)"
                }
                Invoke-MgGraphRequest -Method 'POST' -Uri $Uri -Headers $requestParams.Headers -ContentType "application/json" -Body ($body | ConvertTo-Json)
            }
        }
        
        ## If Group Member isn't in Filtered Devices, remove from group
        foreach ($groupMember in $groupMembers) {
            if ($groupMember.id -notin $filteredDevices.aadObjectId) {
                Write-Host "Removing $($groupMember.displayName) (`"id`":`"$($groupMember.id)`")"
                $Uri = "https://graph.microsoft.com/beta/groups/$groupId/members/$($groupMember.id)/`$ref"
                Invoke-MgGraphRequest -Method 'DELETE' -Uri $Uri -Headers $requestParams.Headers > $null
            }
        }
    }
    return $filteredDevices
}
Export-ModuleMember -Function Get-Win11ReadinessStatus