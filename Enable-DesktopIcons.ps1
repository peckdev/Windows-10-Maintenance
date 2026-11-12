& {
    $ErrorActionPreference = 'Stop'
    $windowsSettings = 'HKCU:\Software\Microsoft\Windows\CurrentVersion'

    $desktopIcons = @(
        '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' # Computer (This PC)
        '{59031A47-3F72-44A7-89C5-5595FE6B30EE}' # User's Files
        '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' # Network
        '{645FF040-5081-101B-9F08-00AA002F954E}' # Recycle Bin
        '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}' # Control Panel
    )

    foreach ($layout in 'NewStartPanel', 'ClassicStartMenu') {
        $iconSettings = "$windowsSettings\Explorer\HideDesktopIcons\$layout"
        New-Item -Path $iconSettings -Force | Out-Null

        foreach ($icon in $desktopIcons) {
            New-ItemProperty -Path $iconSettings -Name $icon `
                -PropertyType DWord -Value 0 -Force | Out-Null
        }
    }

    $themeSettings = "$windowsSettings\Themes"
    New-Item -Path $themeSettings -Force | Out-Null
    New-ItemProperty -Path $themeSettings -Name 'ThemeChangesDesktopIcons' `
        -PropertyType DWord -Value 1 -Force | Out-Null

    Write-Host 'All six desktop icon settings are enabled for your account.'
}
