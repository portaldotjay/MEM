<#
Version: 1.0
Author: Jay Williams
Script: BatchAPGroupTags.ps1
Description:
Uses Graph API to add Group Tags to Autopilot Devices by serial numbers in a CSV. 

Needs App Registration configured. Once that's done, add ClientId, TenantId, and RedirectUri to $token variable. 

Permissions needed are DeviceManagementServiceConfig.ReadWrite.All.

The script is provided "AS IS" with no warranties.
#>

$Token = Get-MsalToken -ClientId "" -TenantId "" -Interactive -RedirectUri ""
$csvPath = Read-Host "Enter CSV Path"
$groupTag = Read-Host "Enter Group Tag"
$serialNumbers = Import-Csv -Path $csvPath

$restResponses = @()
$deviceIds = @()

foreach ($serialNumber in $serialNumbers) {
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?filter=contains(serialNumber,'"+$serialNumber.Serial+"')"
    $restResponse = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Get
    $restResponses += @($restResponse)
    
}

$deviceIds = $restResponses.value.id

foreach ($deviceId in $deviceIds) {
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$deviceId/UpdateDeviceProperties"
    $body = "{`"groupTag`":`"$groupTag`"}"
    $restPost = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Post -Body $body -ContentType 'application/json'
}

