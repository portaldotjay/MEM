New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR -ErrorAction SilentlyContinue

try {
    Get-Item HKCR:\ms-msdt -ErrorAction Stop
    Write-host "MS-MSDT exists. No action needed."
    Exit 0
}
catch {
    Write-host "MS-MSDT doesn't exist. Remediate."
    Exit 1
}