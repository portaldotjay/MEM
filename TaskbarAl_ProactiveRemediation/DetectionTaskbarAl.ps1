try {
    Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' | Select-Object -ExpandProperty TaskbarAl -ErrorAction Stop
    Write-host "TaskbarAl exists"
    Exit 0
}
catch {
    Write-host "TaskbarAl doesn't exist. Remediate."
    Exit 1
}

