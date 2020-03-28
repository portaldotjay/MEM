<#
Version: 1.0
Author: Jay Williams
Script: AddIosDevicesToEnrollmentProfile.ps1
Description:
Uses Graph API to get Enrollment Tokens, Enrollment Profiles, and creates a POST to assign serials to enrollment profile.  

Assumes Graph auth access token variable is $Token. See https://www.thelazyadministrator.com/2019/07/22/connect-and-navigate-the-microsoft-graph-api-with-powershell/ for more details.

The script is provided "AS IS" with no warranties.
#>

Add-Type -AssemblyName System.Windows.Forms,PresentationCore,PresentationFramework,System.Drawing

############ STEP 1 // Enrollment Program Token ############

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select an Enrollment Program Token'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please select an Enrollment Program Token:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

$apiUrl1 = "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings"
$rest1  = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl1 -Method Get
$enTokens = @($rest1.value)

$listboxCollection = @()

foreach ($enToken in $enTokens) {
    $object = New-Object System.Object
    $object | Add-Member -MemberType NoteProperty -Name TokenId -value $enToken.id
    $object | Add-Member -MemberType NoteProperty -Name TokenName -value $enToken.tokenName
    $object | Add-Member -MemberType NoteProperty -Name Token -value $enToken
    $listboxCollection += $object
}

$listBox.Items.AddRange($listboxCollection)

$listBox.ValueMember = "TokenId"
$listBox.DisplayMember = "TokenName"

$form.Controls.Add($listBox)
$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedTokenName = $listBox.SelectedItem.TokenName
    $selectedTokenId = $listBox.SelectedItem.TokenId
}

############ STEP 2 // Enrollment Profile ############

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select an Enrollment Profile'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please select an Enrollment Profile:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

$apiUrl2 = "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$selectedTokenId/enrollmentProfiles"
$rest2  = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl2 -Method Get
$enProfiles = @($rest2.value)

$listboxCollection = @()

foreach ($enProfile in $enProfiles) {
    $object = New-Object System.Object
    $object | Add-Member -MemberType NoteProperty -Name ProfileId -value $enProfile.id
    $object | Add-Member -MemberType NoteProperty -Name ProfileName -value $enProfile.displayName
    $object | Add-Member -MemberType NoteProperty -Name Profile -value $enProfile
    $listboxCollection += $object
}

$listBox.Items.AddRange($listboxCollection)

$listBox.ValueMember = "ProfileId"
$listBox.DisplayMember = "ProfileName"

$form.Controls.Add($listBox)
$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedProfileName = $listBox.SelectedItem.ProfileName
    $selectedProfileId = $listBox.SelectedItem.ProfileId
}

############ STEP 3 // Load CSV and convert to JSON ############

$browse = New-Object System.Windows.Forms.OpenFileDialog
$browse.InitialDirectory = "c.\\"
$browse.Filter = ".csv files (*.csv)|*.CSV"
$browse.FilterIndex = 1

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Path to .CSV of Serial Numbers'
$form.Size = New-Object System.Drawing.Size(400,150)
$form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(125,80)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(200,80)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Path to CSV:'
$form.Controls.Add($label)

$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Location = New-Object System.Drawing.Point(300,38)
$BrowseButton.Size = New-Object System.Drawing.Size(75,22)
$BrowseButton.Text = 'Browse'
$BrowseButton.Add_Click(
    {
        $browse.ShowDialog()
        $textBox.Text = $browse.FileName
    }
)
$form.Controls.Add($BrowseButton)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(285,20)
$textBox.Text = $browse.FileName
$form.Controls.Add($textBox)

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $csv = $textBox.Text
}

$Serials = Get-Content  $csv | ConvertFrom-Csv -Header A

$body = @{
    deviceIds = $Serials.A
}

$body = $body | ConvertTo-Json

############ STEP 4 // Verify and Submit ############

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Verification'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,100)
$label.Text = 'Assign Serial Numbers in '+$csv+' to '+$selectedProfileName+' enrollment profile?'
$form.Controls.Add($label)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $apiUrl3 = "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$selectedTokenId/enrollmentProfiles/$selectedProfileId/updateDeviceProfileAssignment"
    $rest3  = Invoke-WebRequest -Headers @{Authorization = "Bearer $($Token)"} -Uri $apiUrl3 -Method Post -Body $body -ContentType 'application/json'
}

[System.Windows.MessageBox]::Show('Result: '+$rest3.StatusDescription)