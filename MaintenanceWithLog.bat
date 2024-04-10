@echo off

set LOG_FILE=output.log

echo Starting Dism scans... >> %LOG_FILE%
Dism.exe /online /cleanup-image /scanhealth >> %LOG_FILE%
echo Dism scan for health completed. >> %LOG_FILE%
Dism.exe /online /cleanup-image /restorehealth >> %LOG_FILE%
echo Dism restore health completed. >> %LOG_FILE%

echo Starting sfc scans... >> %LOG_FILE%
sfc /scannow >> %LOG_FILE%
echo sfc scans completed. >> %LOG_FILE%
echo --------------------------------------------------------
echo Script created and maintained by www.PeckDevelopment.com
echo Support at BTC bc1qw368jup8wl6uu5mfuw3vxuxw5elpqscata5c9t
echo --------------------------------------------------------
echo Starting Disk Cleaning... >> %LOG_FILE%
cmd.exe /c Cleanmgr /sageset:65535 & Cleanmgr /sagerun:65535 >> %LOG_FILE%
echo Disk cleaning completed. >> %LOG_FILE%

echo Starting CreateRestorePoint... >> %LOG_FILE%
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "PDev", 100, 7 >> %LOG_FILE%
echo Restore point created successfully. >> %LOG_FILE%

echo Updating Google Chrome... >> %LOG_FILE%
"C:\Program Files\Google\Chrome\Application\chrome.exe" --silent-update >> %LOG_FILE%
echo Google Chrome update complete. >> %LOG_FILE%

echo Updating Mozilla Firefox... >> %LOG_FILE%
"C:\Program Files\Mozilla Firefox\firefox.exe" -silent -update >> %LOG_FILE%
echo Mozilla Firefox update complete. >> %LOG_FILE%

echo Restarting Google Chrome... >> %LOG_FILE%
taskkill /f /im chrome.exe >> %LOG_FILE%
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" >> %LOG_FILE%
echo Google Chrome restarted. >> %LOG_FILE%

echo Restarting Mozilla Firefox... >> %LOG_FILE%
taskkill /f /im firefox.exe >> %LOG_FILE%
start "" "C:\Program Files\Mozilla Firefox\firefox.exe" >> %LOG_FILE%
echo Mozilla Firefox restarted. >> %LOG_FILE%

echo All tasks finished. >> %LOG_FILE%
echo Rebooting system... >> %LOG_FILE%

shutdown /r /t 0
