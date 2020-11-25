<#
Version: 1.0
Author: Jay Williams
Script: GetGPOInfo.ps1
Description:
Uses Graph API to retrieve details about Administrative Templates. $gpid variable can be found in the MEMac portal URL after "configurationId". 
Example: The $gpid in this URL is "00000000-0000-0000-0000-00000000000"
https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/AdminTemplatesConfigurationMenu/properties/configurationId/00000000-0000-0000-0000-00000000000/configurationName/_beta_-EdgeConfig

It will spit some errors trying to add some properties that don't exist. 

Needs App Registration configured. Once that's done, add ClientId, TenantId, and RedirectUri to $token variable. 

If you don't have MSAL module installed, you'll need to run "Install-Module -Name MSAL.PS" and follow the prompts. 

Permissions needed are DeviceManagementServiceConfig.Read.All.

The script is provided "AS IS" with no warranties.
#>

$Token = Get-MsalToken -ClientId "" -TenantId "" -Interactive -RedirectUri ""

$gpid = 
$apiUrl = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations/$gpid/definitionValues?expand=definition"
$definitionValues = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Get

$gpos = @()
$i=0

foreach ($object in $definitionValues.value) {
    $id = $object.id
    $apiUrl = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations/8abac7d5-0993-4ccf-b37b-22505e11bd22/definitionValues/$id/presentationValues?expand=presentation"
    $presentationValues = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token.AccessToken)"} -Uri $apiUrl -Method Get
    $gpos += [PSCustomObject]@{
        id = $id
        displayName = $object.definition.displayName
        enabled = $object.enabled
        classType = $object.definition.classType
    }
    if ($presentationValues.value | Get-member -name "value" -MemberType Properties ) {
        $gpos[$i] | Add-Member -MemberType NoteProperty -Name 'value' -Value $presentationValues.value.value
    }
    if ($presentationValues.value.values | Get-member -name "name" -MemberType Properties ) {
        $gpos[$i] | Add-Member -MemberType NoteProperty -Name 'values' -Value $presentationValues.value.values.name
    }
    if ($presentationValues.value.presentation | Get-member -name "items" -MemberType Properties ) {
        $gpos[$i] | Add-Member -MemberType NoteProperty -Name 'valueDescription' -Value $presentationValues.value.presentation.items.displayName[$gpos[$i].value]
    }
    $i++
}

$gpos | Format-List
