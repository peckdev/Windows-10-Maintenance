@echo off
echo --------------------------------------------------------
echo Script created and maintained by www.PeckDevelopment.com
echo Support at BTC bc1qw368jup8wl6uu5mfuw3vxuxw5elpqscata5c9t
echo --------------------------------------------------------
echo Checking for administrator privileges...
@echo off
setlocal

:: Check if C:\PDev directory exists, if not, create it
if not exist "C:\PDev" (
    mkdir "C:\PDev"
    echo Created directory C:\PDev
)

set "url=https://github.com/peckdev/Windows-10-Maintenance/raw/main/Win10-Maintenance.bat"
set "output=C:\PDev\Win10-Maintenance.bat"

echo Downloading file from %url% ...
curl -# -L -o "%output%" "%url%" > nul 2>&1

if %errorlevel% neq 0 (
    echo Error: Failed to download the file.
) else (
    echo File downloaded successfully.
    echo Running the saved file...
    call "%output%"
)

endlocal

echo All tasks finished.
echo Please save all your work if the PC needs a reboot.
echo.
