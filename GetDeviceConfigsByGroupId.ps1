<#
Version: 1.0
Author: Jay Williams
Script: GetDeviceConfigsByGroupId.ps1
Description:
Uses Graph API to get all deviceConfigurations, creates objects from results, filters by groupId.  

Assumes Graph auth access token variable is $Token. See https://www.thelazyadministrator.com/2019/07/22/connect-and-navigate-the-microsoft-graph-api-with-powershell/ for more details.

The script is provided "AS IS" with no warranties.
#>

$groupId = 'GROUPID'

$apiUrl = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?expand=assignments&top=999"

$rest  = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl -Method Get
$responses=$rest.value

$assignments = foreach ($response in $responses) {
    $assignmentsProperties = @{
        displayName = $response.displayName
        id = $response.id
        groupAssignmentId = $response.assignments.target.groupId
    }
    New-Object psobject -Property $assignmentsProperties
}

$assignments | where groupAssignmentId -Contains $groupId | Select displayName
