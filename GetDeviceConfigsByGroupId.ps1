$groupId = '38b22043-8dbc-4e66-96bd-5ef2eca7bbd7'

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