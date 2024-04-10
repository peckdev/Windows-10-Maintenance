@echo off

echo Starting Dism scans...
Dism.exe /online /cleanup-image /scanhealth
echo Dism scan for health completed.
Dism.exe /online /cleanup-image /restorehealth 
echo Dism restore health completed.

echo Starting sfc scans...
sfc /scannow
echo sfc scans completed.

echo Starting Disk Cleaning...
cmd.exe /c Cleanmgr /sageset:65535 & Cleanmgr /sagerun:65535
echo Disk cleaning completed.

echo Starting CreateRestorePoint...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "PDev", 100, 7
echo Restore point created successfully.

echo Updating Google Chrome...
"C:\Program Files\Google\Chrome\Application\chrome.exe" --silent-update
echo Google Chrome update complete.

echo Updating Mozilla Firefox...
"C:\Program Files\Mozilla Firefox\firefox.exe" -silent -update
echo Mozilla Firefox update complete.

echo Restarting Google Chrome...
taskkill /f /im chrome.exe
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe"
echo Google Chrome restarted.

echo Restarting Mozilla Firefox...
taskkill /f /im firefox.exe
start "" "C:\Program Files\Mozilla Firefox\firefox.exe"
echo Mozilla Firefox restarted.

echo All tasks finished.
echo Rebooting system...

shutdown /r /t 0