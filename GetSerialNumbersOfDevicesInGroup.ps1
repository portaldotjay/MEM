<#
Version: 1.0
Author: Jay Williams
Script: GetSerialNumbersOfDevicesInGroup.ps1
Description:
Uses Graph API to get the deviceId of all devices in Group then get's managedDevice by filtering using deviceId. Stores all serials in $serialNumbers.
Enter Group ID on line 22.
If you're getting throttle errors, look at line 25.

Needs App Registration configured. Once that's done, add ClientId, TenantId, and RedirectUri to $token variable. 

If you don't have MSAL module installed, you'll need to run "Install-Module -Name MSAL.PS" and follow the prompts. 

Needs PowerShell 7. Permissions needed are Group.Read.All and DeviceManagementManagedDevices.Read.All.

The script is provided "AS IS" with no warranties.
#>

$Token = Get-MsalToken -ClientId "" -TenantId "" -Interactive -RedirectUri "http://localhost"

#Enter the Azure AD Group ID here.
$groupid = ""

#If you are getting throttle erorrs, lower this number. I found that 5000 at a time with a sleep of 20 seconds worked well for me and didn't get throttle errors for 50k+ devices. 
$numberOfDevices = 5000

#Get Members of group
$apiUrl = "https://graph.microsoft.com/beta/groups/$groupid/transitiveMembers?top=999&select=deviceId"
$rest = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Get

#create members array with nextlink paging
$members = @()
$members += $rest.value
$nextlink = $rest."@odata.nextLink"
while ($nextlink -ne $null){
    $rest = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $nextlink -Method Get
    $nextlink = $rest."@odata.nextLink"
    $members += $rest.value
}

#filter out any members that aren't devices
$devices = $members | where "@odata.type" -EQ "#microsoft.graph.device"

#create serials array by running requests in parallel while trying not to hit Graph throttle limit.
$serialNumbers = [System.Collections.ArrayList]::new()
if ($devices.count -lt $numberOfDevices) {
    $x = $devices.count
} else {
    $x = $numberOfDevices
}
for ($i = 0; $i -lt $devices.Count; ($i++),(sleep 20)) {
    $devices.deviceId[$i..($i+$x)] | ForEach-Object -Parallel {
        $apiUrl1 = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?filter=AzureAdDeviceId eq '$_' &select=serialNumber"
        $rest1 = Invoke-RestMethod -Headers @{Authorization = "Bearer $($using:Token.AccessToken)"} -Uri $apiUrl1 -Method Get
        $serialNumber = $rest1.value.serialNumber
        $dict = $using:serialNumbers
        $dict.Add($serialNumber)
    } -ThrottleLimit 500
    $i = $i+$x 
}
