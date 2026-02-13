Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win {
  [DllImport("user32.dll")]
  public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

$hwnd = (Get-Process -Id $PID).MainWindowHandle
[Win]::ShowWindow($hwnd, 0)

# ==============================
# CONFIG
# ==============================
$WallpaperPath = "C:\wallpaper\johnpork.jpg"
$RegPath = "HKCU:\Control Panel\Desktop"
$RegName = "Wallpaper"

Write-Host "========== Wallpaper Lock Script Starting =========="

# ==============================
# VALIDATION
# ==============================

Write-Host "Checking if wallpaper file exists..."
if (-not (Test-Path $WallpaperPath)) {
    Write-Host "[ERROR] Wallpaper file not found at $WallpaperPath" -ForegroundColor Red
    exit
}
Write-Host "[OK] Wallpaper file found."

Write-Host "Checking registry path..."
if (-not (Test-Path $RegPath)) {
    Write-Host "[ERROR] Registry path $RegPath not accessible." -ForegroundColor Red
    exit
}
Write-Host "[OK] Registry path accessible."

# ==============================
# FUNCTION
# ==============================
function Set-Wallpaper {
    Write-Host "Setting wallpaper to $WallpaperPath"

    try {
        Set-ItemProperty -Path $RegPath -Name $RegName -Value $WallpaperPath
        Write-Host "[OK] Registry updated."

        Write-Host "Refreshing desktop..."
        rundll32.exe user32.dll, UpdatePerUserSystemParameters
        Write-Host "[OK] Desktop refresh triggered."
    }
    catch {
        Write-Host "[ERROR] Failed to set wallpaper: $_" -ForegroundColor Red
    }
}

# ==============================
# INITIAL APPLY
# ==============================
Set-Wallpaper

Write-Host "Wallpaper lock active. Monitoring for changes..."
Write-Host "Press Ctrl+C to stop."
Write-Host "====================================================="

# ==============================
# MONITOR LOOP
# ==============================
while ($true) {
    try {
        $current = (Get-ItemProperty -Path $RegPath -Name $RegName).Wallpaper

        if ($current -ne $WallpaperPath) {
            Write-Host "[ALERT] Wallpaper changed by user. Reverting..."
            Set-Wallpaper
        }
        else {
            Write-Host "Wallpaper intact." -NoNewline
            Write-Host " (Checked $(Get-Date -Format HH:mm:ss))"
        }
    }
    catch {
        Write-Host "[ERROR] Registry read failed: $_" -ForegroundColor Red
    }

    Start-Sleep -Seconds 2
}
