#Requires -Version 7
# Setup Auto-Suspend on RDP Disconnect - Run as Administrator

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Configuration
$LinuxHost = "192.168.1.5"
$LinuxUser = "nasadmin"
$VMName = "Win11"
$TaskName = "AutoSuspend-RDP"

Write-Host "=== Setting up Auto-Suspend on RDP Disconnect ===" -ForegroundColor Cyan

# Create suspend script
$SuspendScript = "$env:ProgramData\rdp-suspend.ps1"
"ssh ${LinuxUser}@${LinuxHost} `"virsh -c qemu:///system suspend ${VMName}`"" | Set-Content $SuspendScript
Write-Host "Created: $SuspendScript"

# Create scheduled task - run as current user so SSH keys work
schtasks /delete /tn $TaskName /f 2>$null
schtasks /create /tn $TaskName `
    /tr "pwsh.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$SuspendScript`"" `
    /sc ONEVENT /ec "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" `
    /mo "*[System[Provider[@Name='Microsoft-Windows-TerminalServices-LocalSessionManager'] and (EventID=24)]]" `
    /ru "$env:USERDOMAIN\$env:USERNAME" /it /f

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSUCCESS: VM will suspend on RDP disconnect." -ForegroundColor Green
    Write-Host "NOTE: Ensure SSH key auth works for ${LinuxUser}@${LinuxHost}" -ForegroundColor Yellow
} else {
    Write-Host "`nERROR: Failed to create task." -ForegroundColor Red
}

Read-Host "`nPress Enter to exit"
