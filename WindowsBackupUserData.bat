@echo off

REM Set the backup folder path
set "BackupFolder=C:\Backup"

REM Create the backup folder if it doesn't exist
if not exist "%BackupFolder%" mkdir "%BackupFolder%"

REM Get the path of the user's profile folders
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Desktop" 2^>nul') do (
    set "DesktopPath=%%b"
)

for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Documents" 2^>nul') do (
    set "DocumentsPath=%%b"
)

for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Downloads" 2^>nul') do (
    set "DownloadsPath=%%b"
)

REM Copy folders using robocopy
echo Copying Desktop folder...
robocopy "%DesktopPath%" "%BackupFolder%\Desktop" /E /Z /ETA /LOG+:"%BackupFolder%\robocopy_log.txt"

echo Copying Documents folder...
robocopy "%DocumentsPath%" "%BackupFolder%\Documents" /E /Z /ETA /LOG+:"%BackupFolder%\robocopy_log.txt"

echo Copying Downloads folder...
robocopy "%DownloadsPath%" "%BackupFolder%\Downloads" /E /Z /ETA /LOG+:"%BackupFolder%\robocopy_log.txt"

REM Calculate and display final disk space used
echo.
echo Final disk space used in the backup folder:
dir "%BackupFolder%" /s

pause
