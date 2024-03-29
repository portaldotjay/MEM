$regBkpPath = "C:\Intune\RegBackup\"

if ( -not (Test-Path $regBkpPath)) {
    New-Item -Path $regBkpPath -ItemType Directory
}

Invoke-Command {reg export 'HKCR\ms-msdt' $regBkpPath\msmsdtBkp.reg /y}

New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR -ErrorAction SilentlyContinue
Remove-Item -Path 'HKCR:\ms-msdt\*' -Recurse -Force -Confirm:$false
Remove-Item -Path 'HKCR:\ms-msdt\' -Force -Confirm:$false