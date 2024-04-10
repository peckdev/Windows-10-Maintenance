@echo off
echo --------------------------------------------------------
echo Script created and maintained by www.PeckDevelopment.com
echo Support at BTC bc1qw368jup8wl6uu5mfuw3vxuxw5elpqscata5c9t
echo --------------------------------------------------------
echo Checking for administrator privileges...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo You have administrative privileges.
) else (
    echo You do not have administrative privileges.
    echo Please run this script as an administrator.
    echo Elevating...
    powershell -Command "Start-Process '%0' -Verb RunAs"
    exit /b
)
echo --------------------------------------------------------
echo Script created and maintained by www.PeckDevelopment.com
echo Support at BTC bc1qw368jup8wl6uu5mfuw3vxuxw5elpqscata5c9t
echo --------------------------------------------------------
echo Checking for Windows updates...
net start wuauserv
echo Waiting for updates to be checked...
timeout /t 10 /nobreak >nul
wuauclt /detectnow
echo Updates have been triggered to check. Please wait...
timeout /t 60 /nobreak >nul
echo Windows update check complete.
echo Installing updates...
wusa.exe /detectnow /quiet /norestart
echo Updates have been installed.
echo Starting Dism scans...
Dism.exe /online /cleanup-image /scanhealth
Dism.exe /online /cleanup-image /restorehealth 

echo Starting sfc scans...
sfc /scannow

echo Starting Disk Cleaning...
Add-Type -AssemblyName System.Windows.Forms

# Start Disk Cleanup and wait for it to open
Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sageset:65535" -WindowStyle Hidden
Start-Sleep -Seconds 5  # Wait for Disk Cleanup to open

# Define the handle to the Disk Cleanup window
$diskCleanupWindow = Get-Process | Where-Object { $_.MainWindowTitle -like "Disk Cleanup*" }

# Wait for the window to become active
while (-not $diskCleanupWindow.MainWindowHandle) {
    Start-Sleep -Milliseconds 500
    $diskCleanupWindow.Refresh()
}

# Wait for Disk Cleanup to finish loading
Start-Sleep -Seconds 5

# Use Windows API to send messages to the window to check all checkboxes and run cleanup
$handle = $diskCleanupWindow.MainWindowHandle

# Constants for Windows messages
$BM_CLICK = 0xF5
$WM_SETFOCUS = 0x0007
$WM_COMMAND = 0x0111

# Check all checkboxes
for ($i = 0; $i -le 12; $i++) {
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait("{SPACE}")
    Start-Sleep -Milliseconds 100
}

# Click OK to start cleanup
$null = [System.Windows.Forms.SendMessage]::SendMessage($handle, $WM_COMMAND, $BM_CLICK, 0)

# Wait for Disk Cleanup to close
$diskCleanupWindow.WaitForExit()


echo Starting CreateRestorePoint...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "PDev", 100, 7

echo All tasks finished.
echo Please save all your work if the PC needs a reboot.
echo.

set /p choice=Do you want to restart now? (Y/N): 
if /i "%choice%"=="Y" (
    shutdown /r /t 0
) else (
    echo You chose not to restart. Press any key to exit.
    pause >nul
)
