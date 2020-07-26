<#
Version: 1.0
Author: Jay Williams
Script: BatchRenameWindows.ps1
Description:
Uses Graph API to rename devices by serial numbers in a CSV. 

Permissions needed are DeviceManagementManagedDevices.Read.All and DeviceManagementManagedDevices.PriviligedOperations.All.

Assumes Graph auth access token variable is $Token.

The script is provided "AS IS" with no warranties.
#>

$deviceName = "" #Can use {{rand:x}} or {{serialnumber}}
$csvPath = ""
$serialNumbers = Import-Csv -Path $csvPath
$restResponses = @()
$deviceIds = @()

foreach ($serialNumber in $serialNumbers) {
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=serialnumber eq '"+$serialNumber.Serial+"'"
    $restResponse = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl -Method Get
    $restResponses += @($restResponse)
    
}

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
    $restPost = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl -Method Post -Body "+$bodyJson+" -ContentType 'application/json'
    
    $i+=99

}