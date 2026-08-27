@echo off
:: File: Win10-Maintenance.bat
:: Script created and maintained by www.PeckDevelopment.com
:: Support at BTC bc1qflrqcnzdv0d33p7qll8fn4ht50hheavs5w0usd
::
:: Usage: Win10-Maintenance.bat  (double-click, self-elevates)
:: Full DISM output -> C:\Windows\Logs\DISM\dism.log
:: Full SFC  output -> C:\Windows\Logs\CBS\CBS.log
setlocal EnableExtensions EnableDelayedExpansion

:: ================= CONFIG =================
:: Set to 1 to disable password expiry on local accounts. Off by default:
:: it is a CIS/STIG finding, and the old wmic line hit domain accounts on a DC.
set "DISABLE_PW_EXPIRY=0"

set "DO_RESTORE_POINT=1"
set "DO_UPDATES=1"
set "DO_REPAIR=1"
set "DO_CLEANUP=1"

:: cleanmgr profile id (0-9999). Handlers below are left alone on purpose.
set "CLEAN_PROFILE=100"
set "CLEAN_SKIP='DownloadsFolder','Recycle Bin','Previous Installations','Windows Upgrade Log Files'"
:: ==========================================

set "PS=powershell -NoProfile -ExecutionPolicy Bypass -Command"
set "LOGDIR=%ProgramData%\PeckDevelopment"
set "LOG=%LOGDIR%\maintenance.log"
set "WARNCOUNT=0"

:: ---------- Elevation ----------
net session >nul 2>&1
if not %errorlevel%==0 (
    if /i "%~1"=="/elevated" (
        echo ERROR: Elevation was declined or failed.
        pause
        exit /b 1
    )
    echo Elevating...
    %PS% "Start-Process -FilePath '%~f0' -ArgumentList '/elevated' -WorkingDirectory '%~dp0' -Verb RunAs"
    exit /b 0
)

if not exist "%LOGDIR%" md "%LOGDIR%" >nul 2>&1
call :Log "=== Run started %DATE% %TIME% on %COMPUTERNAME% ==="

call :Banner
echo Log: %LOG%

:: ---------- 1. Restore point FIRST ----------
:: The original created this LAST, after every change, so it captured the
:: post-change state and gave nothing to roll back to.
if "%DO_RESTORE_POINT%"=="1" (
    echo.
    echo ==^> Creating system restore point...
    %PS% "$k='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'; $n='SystemRestorePointCreationFrequency'; $o=(Get-ItemProperty $k -Name $n -EA SilentlyContinue).$n; New-ItemProperty -Path $k -Name $n -Value 0 -PropertyType DWord -Force ^| Out-Null; try { Enable-ComputerRestore -Drive '%SystemDrive%\' -EA SilentlyContinue; Checkpoint-Computer -Description 'PDev Maintenance' -RestorePointType MODIFY_SETTINGS -EA Stop; Write-Host '    [ OK ] Restore point created.' } catch { Write-Host ('    [WARN] ' + $_.Exception.Message); exit 1 } finally { if ($null -ne $o) { Set-ItemProperty $k -Name $n -Value $o } else { Remove-ItemProperty $k -Name $n -EA SilentlyContinue } }"
    if errorlevel 1 call :Warn "Restore point failed"
)

:: ---------- 2. Password expiry (opt-in) ----------
if "%DISABLE_PW_EXPIRY%"=="1" (
    echo.
    echo ==^> Disabling password expiration...
    %PS% "if ((Get-CimInstance Win32_ComputerSystem).DomainRole -ge 4) { Write-Host '    [WARN] Domain controller - skipped.'; exit 1 } else { Get-LocalUser ^| Where-Object { $_.Enabled -and -not $_.PasswordNeverExpires } ^| ForEach-Object { try { Set-LocalUser -Name $_.Name -PasswordNeverExpires $true -EA Stop; Write-Host ('    [ OK ] ' + $_.Name) } catch { Write-Host ('    [WARN] ' + $_.Name) } } }"
    if errorlevel 1 call :Warn "Password expiry step skipped on domain controller"
)

:: ---------- 3. Windows Update ----------
:: wuauclt /detectnow has been a no-op since Win10 1709.
:: wusa.exe /detectnow was never valid - wusa installs a specific .msu you hand it.
if "%DO_UPDATES%"=="1" (
    echo.
    echo ==^> Windows Update...
    sc query wuauserv | find "RUNNING" >nul 2>&1 || net start wuauserv >nul 2>&1
    %PS% "if (Get-Module -ListAvailable PSWindowsUpdate) { Import-Module PSWindowsUpdate; $f = Get-WindowsUpdate -MicrosoftUpdate; if ($f) { Write-Host ('    ' + $f.Count + ' update(s) found. Installing...'); Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Confirm:$false ^| Out-String ^| Write-Host } else { Write-Host '    [ OK ] No applicable updates.' } } else { Write-Host '    [WARN] PSWindowsUpdate not installed - using UsoClient, which reports nothing back.'; Write-Host '           Install once: Install-Module PSWindowsUpdate -Force -Scope AllUsers'; UsoClient StartInteractiveScan; Start-Sleep 5; UsoClient StartDownload; UsoClient StartInstall }"
)

:: ---------- 4. Component store + SFC ----------
if "%DO_REPAIR%"=="1" (
    echo.
    echo ==^> Scanning component store...
    Dism.exe /Online /Cleanup-Image /ScanHealth > "%TEMP%\pdev_dism.txt" 2>&1
    type "%TEMP%\pdev_dism.txt"

    :: Only pay the RestoreHealth cost if the scan found something.
    :: Non-English Windows won't match the string, so it falls through to repairing - safe default.
    findstr /i /c:"No component store corruption detected" "%TEMP%\pdev_dism.txt" >nul 2>&1
    if errorlevel 1 (
        echo     Corruption reported - running /RestoreHealth...
        Dism.exe /Online /Cleanup-Image /RestoreHealth
        if errorlevel 1 (
            call :Warn "DISM /RestoreHealth returned !errorlevel!"
        ) else (
            echo     [ OK ] Component store repaired.
        )
    ) else (
        echo     [ OK ] Store healthy - skipping /RestoreHealth.
    )
    del "%TEMP%\pdev_dism.txt" >nul 2>&1

    echo.
    echo ==^> Running SFC...
    sfc.exe /scannow
    if errorlevel 1 call :Warn "sfc returned !errorlevel!"
)

:: ---------- 5. Disk cleanup ----------
:: /sageset opens a GUI and blocks waiting for a human, and conflicts with
:: /verylowdisk. Write the StateFlags directly, then one silent /sagerun.
if "%DO_CLEANUP%"=="1" (
    echo.
    echo ==^> Disk cleanup...
    for /f %%F in ('%PS% "[math]::Round((Get-PSDrive %SystemDrive:~0,1%).Free/1GB,2)"') do set "FREE_BEFORE=%%F"

    %PS% "$skip=@(%CLEAN_SKIP%); $f='StateFlags'+('%CLEAN_PROFILE%'.PadLeft(4,'0')); Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches' ^| ForEach-Object { $v = if ($skip -contains $_.PSChildName) {0} else {2}; New-ItemProperty -Path $_.PSPath -Name $f -Value $v -PropertyType DWord -Force ^| Out-Null }"

    start "" /wait cleanmgr.exe /sagerun:%CLEAN_PROFILE%

    for /f %%F in ('%PS% "[math]::Round((Get-PSDrive %SystemDrive:~0,1%).Free/1GB,2)"') do set "FREE_AFTER=%%F"
    echo     [ OK ] Free space: !FREE_BEFORE! GB -^> !FREE_AFTER! GB
)

:: ---------- Summary ----------
echo.
call :Banner
if %WARNCOUNT% GTR 0 (
    echo %WARNCOUNT% warning^(s^) - see %LOG%
) else (
    echo All tasks finished with no warnings.
)
call :Log "=== Run finished %DATE% %TIME% - %WARNCOUNT% warning(s) ==="

set "PENDING=0"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" >nul 2>&1 && set "PENDING=1"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1 && set "PENDING=1"

echo.
if "%PENDING%"=="1" (
    echo A reboot is PENDING. Save your work.
) else (
    echo No reboot flags detected.
)

choice /c YN /n /t 60 /d N /m "Restart now? (Y/N, auto-N in 60s): "
if errorlevel 2 goto :NoRestart
shutdown /r /t 30 /c "PDev Maintenance"
echo Restarting in 30 seconds. Run  shutdown /a  to cancel.
timeout /t 5 >nul
exit /b 0

:NoRestart
echo Not restarting. Press any key to exit.
pause >nul
exit /b 0

:: ---------- Helpers ----------
:Banner
echo --------------------------------------------------------
echo Script created and maintained by www.PeckDevelopment.com
echo Support at BTC bc1qflrqcnzdv0d33p7qll8fn4ht50hheavs5w0usd
echo --------------------------------------------------------
goto :eof

:Warn
set /a WARNCOUNT+=1
echo     [WARN] %~1
call :Log "WARN: %~1"
goto :eof

:Log
echo [%DATE% %TIME%] %~1>>"%LOG%" 2>nul
goto :eof
