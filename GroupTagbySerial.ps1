<#
Version: 1.0
Author: Jay Williams
Script: GroupTagbySerial.ps1
Description:
Uses Graph API to get Autopilot Devices by Serial and pass the Autopilot Device identitities ID to use for UpdateDeviceProperties. In my case, the body just needed a grouptag but can include userPrincipalName, addressableUserName, groupTag, or displayName. Just modify the body to the correct JSON format if adding more properties. 

Assumes Graph auth access token variable is $Token. See https://www.thelazyadministrator.com/2019/07/22/connect-and-navigate-the-microsoft-graph-api-with-powershell/ for more details.
The script is provided "AS IS" with no warranties.
#>

$grouptag = ''
$path = ''

$body = '{"groupTag":"'+$groupTag+'"}'
$sns = Import-Csv $path
foreach ($sn in $sns) {
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?filter=contains(serialNumber,'"+$sn.serials+"')"
    $rest = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl -Method Get
    $id = $rest.value.id
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$id/UpdateDeviceProperties"
    $rest = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl -Body $body -Method Post -ContentType 'application/json'
}
