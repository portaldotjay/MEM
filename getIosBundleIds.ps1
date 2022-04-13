# Required module: Microsoft.Graph.Devices.CorporateManagement

Connect-MgGraph -Scopes DeviceManagementApps.Read.All
Select-MgProfile 'beta'
$mobileApps = Get-MgDeviceAppMgtMobileApp
foreach ($mobileApp in $mobileApps) {
    $mobileApp | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value $mobileApp.AdditionalProperties.'@odata.type'
    $mobileApp | Add-Member -MemberType NoteProperty -Name 'bundleId' -Value $mobileApp.AdditionalProperties.'bundleId'
}

$mobileApps | where '@odata.type' -Like "*ios*" | select DisplayName,bundleId
