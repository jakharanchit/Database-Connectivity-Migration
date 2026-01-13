# Check-MSOLEDBSQL-Drivers.ps1
# Description: Verifies the installation of Microsoft OLE DB Driver for SQL Server.
# Checks both 64-bit and 32-bit (WOW64) registry hives.

Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   Database Connectivity Driver Verification Utility" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$driverName = "MSOLEDBSQL"
$found = $false

# Function to check a specific registry path
function Check-RegistryPath {
    param (
        [string]$Path,
        [string]$Architecture
    )

    if (Test-Path $Path) {
        $drivers = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | 
                   Where-Object { $_.Name -like "*$driverName*" }
        
        if ($drivers) {
            foreach ($driver in $drivers) {
                $props = Get-ItemProperty $driver.PSPath
                Write-Host "[$Architecture] Found: $($props.Description)" -ForegroundColor Green
                Write-Host "    Version: $($props.Version)" -ForegroundColor Gray
                Write-Host "    Path:    $($driver.Name)" -ForegroundColor Gray
                Write-Host ""
                return $true
            }
        }
    }
    return $false
}

# 1. Check 64-bit Registry (Native)
$found64 = Check-RegistryPath -Path "HKLM:\SOFTWARE\Microsoft" -Architecture "64-bit System"

# 2. Check 32-bit Registry (WOW6432Node - Critical for LabVIEW/32-bit Apps)
$found32 = Check-RegistryPath -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft" -Architecture "32-bit WOW64"

# Summary
if ($found64 -or $found32) {
    Write-Host "SUMMARY: Driver detected." -ForegroundColor Green
    if (-not $found32) {
        Write-Host "WARNING: 32-bit driver not found. 32-bit applications (like standard LabVIEW) may fail." -ForegroundColor Yellow
        Write-Host "Solution: Install the x64 .msi (it includes both architectures)." -ForegroundColor Yellow
    }
}
else {
    Write-Host "SUMMARY: MSOLEDBSQL Driver NOT found." -ForegroundColor Red
    Write-Host "Action Required: Download and install 'Microsoft OLE DB Driver 19 for SQL Server'." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..." -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")