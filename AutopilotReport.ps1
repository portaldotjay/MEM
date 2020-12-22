<#
Version: 1.0
Author: Jay Williams
Script: todaysAutopilotReport.ps1
Description:
Uses Graph API to get Autopilot deployments detail, display basic stats, and exports a CSV with more detiails. 

Needs App Registration configured. Once that's done, add ClientId, TenantId, and RedirectUri to $token variable. 

If you don't have MSAL module installed, you'll need to run "Install-Module -Name MSAL.PS" and follow the prompts. 

Permissions needed are DeviceManagementManagedDevices.Read.All.

The script is provided "AS IS" with no warranties.
#>

$Token = Get-MsalToken -ClientId "" -TenantId "" -Interactive -RedirectUri ""

$days = Read-Host "How many days worth?"
# $date = ((Get-Date).AddDays(-1).ToString("yyyy/MM/dd") | foreach {$_ -replace "/","-"})+"T08:00:00.000Z"
$date = (Get-Date).AddHours(8).AddDays(-$days).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

$apiUrl = "https://graph.microsoft.com/beta/deviceManagement/autopilotEvents?top=100&filter=microsoft.graph.DeviceManagementAutopilotEvent/enrollmentStartDateTime ge $date"
$request = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Get
$deployments = @($request.value)

while ($request.value.count -eq 100){
    $nextlink = $request.'@odata.nextLink'
    $request = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $nextlink -Method Get
    $deployments += @($request.value)
}

$completed = $deployments | where {$_.deploymentState -eq 'success'}
$inProgress = $deployments | where {$_.deploymentState -eq 'inProgress'}
$failed = $deployments | where {$_.deploymentState -eq 'failure'}
$durations = $deployments.deploymentTotalDuration -replace "PT"

for ($i = 0; $i -lt $durations.Count; $i++) {
    if ($durations[$i] -notmatch "M") {
        $durations[$i] = "00M"+$durations[$i]
    }
    if ($durations[$i] -notmatch "..M") {
        $durations[$i] = "0"+$durations[$i]
    }
    if($durations[$i] -notmatch "..M..\.") {
        $durations[$i] = $durations[$i].Insert(3,0)
    }
    $durations[$i] = ($durations[$i] -replace "\..*","s" -replace "M",":" -replace "s").Insert(0,"00:")
    $durations[$i] = [timespan]$durations[$i]
    $deployments[$i].deploymentTotalDuration = $durations[$i]
}

$averageSuccessDuration = New-TimeSpan -seconds ((($deployments).where{$_.deploymentState -eq "success"}).deploymentTotalDuration.TotalSeconds | measure -Average).Average
$averageFailDuration = New-TimeSpan -seconds ((($deployments).where{$_.deploymentState -eq "failure"}).deploymentTotalDuration.TotalSeconds | measure -Average).Average

$filename = "AutopilotResults.csv"
$deployments | select @{n='Serial Number';e={$_.deviceSerialNumber}},@{n='Deployment Time';e={$_.deploymentTotalDuration}},@{n='Autopilot Profile';e={$_.windowsAutopilotDeploymentProfileDisplayName}},@{n='Enrollment Status';e={$_.deploymentState}}  | Export-Csv -path $filename -NoTypeInformation

Write-Host "Total completed:"$completed.count
Write-Host "Total in-progress:"$inProgress.count
Write-Host "Total failed:"$failed.count
Write-Host "Average completion time:"($averageSuccessDuration.Minutes)"minutes and"($averageSuccessDuration.Seconds)"seconds."
Write-Host "Average failure time:"($averageFailDuration.Minutes)"minutes and"($averageFailDuration.Seconds)"seconds."
