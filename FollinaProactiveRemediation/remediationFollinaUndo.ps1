$regBkpPath = "C:\Intune\RegBackup\"

New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR -ErrorAction SilentlyContinue

If (-not(Test-Path HKCR:\ms-msdt)) {
    Start-Process reg -ArgumentList "import $regBkpPath\msmsdtBkp.reg"
}