#Requires -Version 5.1
<#
.SYNOPSIS
Sets the current user's Windows desktop background to solid black.
.DESCRIPTION
Clears the wallpaper and saves black as the background color. Run in the
interactive Windows session you want to change. No elevation is required.
#>

$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This script requires Windows.'
}

if (-not ('PeckDev.DesktopBackground' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace PeckDev
{
    public static class DesktopBackground
    {
        private const uint SetDesktopWallpaper = 0x0014;
        private const uint UpdateUserProfile = 0x0001;
        private const uint SendChange = 0x0002;
        private const int DesktopColor = 1;

        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool SystemParametersInfo(
            uint action, uint parameter, string value, uint flags);

        [DllImport("user32.dll")]
        private static extern bool SetSysColors(int count, int[] elements, uint[] colors);

        public static void ApplyBlack()
        {
            if (!SystemParametersInfo(SetDesktopWallpaper, 0, "",
                                      UpdateUserProfile | SendChange))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(),
                                         "Windows could not clear the desktop wallpaper.");
            }

            if (!SetSysColors(1, new[] { DesktopColor }, new uint[] { 0 }))
            {
                throw new InvalidOperationException("Windows could not apply the black desktop color.");
            }
        }
    }
}
'@
}

[PeckDev.DesktopBackground]::ApplyBlack()

# SetSysColors applies to the session. Save the color for future sign-ins.
$backgroundColor = @{
    LiteralPath  = 'HKCU:\Control Panel\Colors'
    Name         = 'Background'
    PropertyType = 'String'
    Value        = '0 0 0'
}
New-ItemProperty @backgroundColor -Force | Out-Null

Write-Host 'Desktop background set to solid black for the current user.'
