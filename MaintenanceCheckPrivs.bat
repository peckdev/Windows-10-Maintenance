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

echo Disabling password expiration...
wmic path Win32_UserAccount set PasswordExpires=False
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

@echo off
echo Starting Disk Cleaning...
cmd.exe /c Cleanmgr /sageset:65535 /verylowdisk & Cleanmgr /sagerun:65535 /verylowdisk


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
