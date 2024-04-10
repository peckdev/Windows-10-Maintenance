@echo off
set /p file_path=Enter the path to the file: 

if "%file_path%"=="" (
    echo File path cannot be empty.
    pause
    exit /b 1
)

if not exist "%file_path%" (
    echo File does not exist.
    pause
    exit /b 1
)

echo Checking signature of file: %file_path%
certutil -hashfile "%file_path%" SHA256
pause
