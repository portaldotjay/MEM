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

foreach ($serialNumber in $serialNumbers) {
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?filter=contains(serialNumber,'"+$serialNumber.Serial+"')"
    $restResponse = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Get
    $deviceId = $restResponse.value.id
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$deviceId/UpdateDeviceProperties"
    $body = "{`"groupTag`":`"$groupTag`"}"
    $postResponse = Invoke-WebRequest -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Post -Body $body -ContentType 'application/json'
    if ($postResponse.statusCode -eq '200') {
        Write-Host $serialNumber.serial"Successful"
    } else {
        Write-Host $serialNumber.serial"Unsuccessful"
    }
}
