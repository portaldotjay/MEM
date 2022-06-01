New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR -ErrorAction SilentlyContinue

Remove-Item -Path 'HKCR:\ms-msdt\*' -Recurse -Force -Confirm:$false
Remove-Item -Path 'HKCR:\ms-msdt\' -Force -Confirm:$false