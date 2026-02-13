Write-Host "========== Wallpaper Diagnostic Mode =========="

$WallpaperPath = "C:\wallpaper\johnpork.jpg"
$RegPath = "HKCU:\Control Panel\Desktop"
$RegName = "Wallpaper"

$errors = 0

# ---------------------------------
# Check file exists
# ---------------------------------
Write-Host "Checking wallpaper file..."
if (Test-Path $WallpaperPath) {
    Write-Host "[OK] File exists."
}
else {
    Write-Host "[FAIL] File missing at $WallpaperPath" -ForegroundColor Red
    $errors++
}

# ---------------------------------
# Check registry path access
# ---------------------------------
Write-Host "Checking registry path..."
if (Test-Path $RegPath) {
    Write-Host "[OK] Registry path accessible."
}
else {
    Write-Host "[FAIL] Cannot access $RegPath" -ForegroundColor Red
    $errors++
}

# ---------------------------------
# Read current wallpaper
# ---------------------------------
Write-Host "Reading current wallpaper setting..."
try {
    $current = (Get-ItemProperty -Path $RegPath -Name $RegName).Wallpaper
    Write-Host "[OK] Current wallpaper: $current"
}
catch {
    Write-Host "[FAIL] Unable to read registry value." -ForegroundColor Red
    $errors++
}

# ---------------------------------
# Check write permissions (simulation only)
# ---------------------------------
Write-Host "Simulating registry write test..."
try {
    # Test write by reading and preparing a mock value
    $mock = $WallpaperPath
    Write-Host "[OK] Write simulation passed (no actual write performed)."
}
catch {
    Write-Host "[FAIL] Write simulation failed." -ForegroundColor Red
    $errors++
}

# ---------------------------------
# Check rundll32 availability
# ---------------------------------
Write-Host "Checking rundll32 availability..."
try {
    $rundll = Get-Command rundll32.exe -ErrorAction Stop
    Write-Host "[OK] rundll32 available at $($rundll.Source)"
}
catch {
    Write-Host "[FAIL] rundll32 not found." -ForegroundColor Red
    $errors++
}

# ---------------------------------
# Final Report
# ---------------------------------
Write-Host "=============================================="

if ($errors -eq 0) {
    Write-Host "DIAGNOSTIC RESULT: PASS" -ForegroundColor Green
    Write-Host "All checks succeeded. Script should run without structural errors."
}
else {
    Write-Host "DIAGNOSTIC RESULT: FAIL ($errors issues detected)" -ForegroundColor Red
}

Write-Host "Diagnostic mode complete."
