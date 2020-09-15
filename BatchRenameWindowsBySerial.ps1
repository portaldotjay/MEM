<#
Version: 1.1
Author: Jay Williams
Script: BatchRenameWindows.ps1
Description:
Uses Graph API to rename devices by serial numbers in a CSV. 

Permissions needed are DeviceManagementManagedDevices.Read.All and DeviceManagementManagedDevices.PriviligedOperations.All.

The script is provided "AS IS" with no warranties.
#>

$deviceName = "" #Can use {{rand:x}} or {{serialnumber}}
$csvPath = ""
$tenentId = ""
$clientid = ""
$redirectURI = ""

$serialNumbers = Import-Csv -Path $csvPath
$Token = Get-MsalToken -ClientId $clientid -TenantId $tenentId -Interactive -RedirectUri $redirectURI



# Gets deviceId by filtering serialNumber
$restResponses = @()
$deviceIds = @()
foreach ($serialNumber in $serialNumbers) {
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=serialnumber eq '"+$serialNumber.serialNumber+"'"
    $restResponse = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Get
    $restResponses += @($restResponse)
    
}

# Loops through $deviceIds array limited to 100 devices at a time
$deviceIds = $restResponses.value.id
$apiUrl = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/executeAction"

for ($i = 0; $i -ile $deviceIds.Count; $i++) {
    $deviceNameValue = @{}
    foreach ($deviceId in $deviceIds[$i..($i+99)]) {
        $deviceNameValue.Add($deviceId, $deviceName)
        $body = @{
            deviceName = $deviceNameValue | ConvertTo-Json -Compress
            platform   = "windows"
            restartNow = $False
            actionName = "setDeviceName"
            action     = "setDeviceName"
            deviceIds  = $deviceIds[$i..($i+99)]
            realAction = "setDeviceName"
        }
    }  

    $bodyJson = $body | ConvertTo-Json -Compress
    $restPost = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Post -Body $bodyJson -ContentType 'application/json'
    
    $i+=99

}
