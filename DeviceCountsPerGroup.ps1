<#
Version: 1.0
Author: Jay Williams
Script: DeviceCountsPerGroup.ps1
Description:
This is a three level groups process. The first group is the main group that all the subgroups come from. 
Then the transitive members (groups and devices) are pulled out and listed.
A custom object "$group" is created with count, members, and groupname properties. 
The groupName = Subgroup Name, Members are groups inside subgroups, and count is number of devices in subgroup.
Assumes $token is access token.
The script is provided "AS IS" with no warranties.
#>

$maingroupid = ""

#Get Direct Members of "Main" group
$apiUrl = "https://graph.microsoft.com/beta/groups/$maingroupid/members?top=999"
$rest = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl -Method Get
$dirGroups = $rest.value

#create schoolgroups array
$group = @()

#Send Request to groups with direct membership to "All Intune Student PC's" group
foreach ($dirGroup in $dirGroups) {
    $apiUrl1 = "https://graph.microsoft.com/beta/groups/"+$dirGroup.id+"/transitivemembers?top=999"
    $rest1  = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl1 -Method Get
    $memberDevices = @($rest1.value | where-object -Property "@odata.type" -eq "#microsoft.graph.device").displayName | Sort-Object
    $memberGroups = @($rest1.value | where-object -Property "@odata.type" -eq "#microsoft.graph.group").displayName | Sort-Object
    $count = $memberDevices.count
#Pagination for results > 100
    $nextlink = $rest1."@odata.nextLink"
    while ($nextlink -ne $null){
        $rest2 = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $nextlink -Method Get
        $nextlink = $rest2."@odata.nextLink"
        $memberDevices += ($rest2.value | where-object -Property "@odata.type" -eq "#microsoft.graph.device").displayName | Sort-Object
        $memberGroups += ($rest2.value | where-object -Property "@odata.type" -eq "#microsoft.graph.group").displayName | Sort-Object
        $count += $memberDevices.count
    }
    $count = $memberDevices.Count
    $groups = New-Object psobject -Property @{
        GroupName = $dirGroup.displayName
        Members = @($memberGroups).Where({$null -ne $_}) -join ", "   
        Count   = $count
    }
    $group += $groups
}
