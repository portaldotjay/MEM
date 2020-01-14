<#
Version: 1.0
Author: Jay Williams
Script: RevokeFailedLicense.ps1
Description:
Find all app id of failed iOS installs, find the devices it failed on, revoke license.
This often times fixes failed iOS isntalls. Can run for single app id as well.  
Release notes: Must setup Graph API registration in azure. Assumes auth token is $Tokenresponse.
Version 1.0: Original published version. 
The script is provided "AS IS" with no warranties.
#>

#   Assumes Graph auth access token variable is $Tokenresponse.access_token. See https://www.thelazyadministrator.com/2019/07/22/connect-and-navigate-the-microsoft-graph-api-with-powershell/ for more details.

#   If you want to do a single app instead of all failed; comment line 8 out, uncomment line 9, and replace the app id. 

#   Get Id of all iOS apps that have failedDeviceCount greater than 0
$apiUrl1 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?filter=installSummary/failedDeviceCount gt 0 and isof('microsoft.graph.iosVppApp')&expand=installSummary&select=id"
$rest1 = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl1 -Method Get

#   Create array of all app ids
#$appIds = @($rest1.value.id)
$appIds = @("83310a6a-1e8b-4c1c-8c8f-abc55ce21c96")

#   clear array of all deviceIds that have failed installs (useful if running twice)
Clear-Variable -Name failedIds

#   Loop GET request using $appids array to get deviceIds of failed install and add those deviceIds to $failedIds array
foreach ($appId in $appIds) {
    $apiUrl2 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/"+$appId+"/deviceStatuses/?filter=(installState eq 'failed')"
    $rest2 = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl2 -Method Get
    $failedIds += @($rest2.value.deviceId)
    }

#   Loop POST request using $failedIds array to revoke app license on device app install failed on
foreach ($failedId in $failedIds) {
    $apiUrl3 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/"+$appId+"/microsoft.graph.iosVppApp/revokeDeviceLicense"
    $body = @{
        managedDeviceId=$failedId
        notifyManagedDevices= $false
        }
    $json = ConvertTo-Json $body
    $rest3 = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl3 -Method Post -Body $json -ContentType 'application/json'
    }

#   Loop POST request using $failedIds array to sync devices
foreach ($failedId in $failedIds) {
    $apiUrl5 = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/"+$failedId+"/syncDevice"
    $rest5 = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl5 -Method Post
    }

#   Loop GET request using $appIds that failed to return revokeLicenseActionResults.
foreach ($appId in $appIds) {
    $apiUrl4 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/"+$appid+"/?select=microsoft.graph.iosVppApp/revokeLicenseActionResults"
    $rest4 = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl4 -Method Get
    $rest4.revokeLicenseActionResults | select managedDeviceId, actionState
    }