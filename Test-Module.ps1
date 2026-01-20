# Test script to verify the Install-Aloevera module loads correctly

Write-Host "Testing Install-Aloevera Module..." -ForegroundColor Cyan
Write-Host ""

# Import the module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "Install-Aloevera\Install-Aloevera.psd1"

Write-Host "[1/5] Importing module..." -NoNewline
try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host " [OK]" -ForegroundColor Green
} catch {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Check if module is loaded
Write-Host "[2/5] Verifying module loaded..." -NoNewline
$module = Get-Module -Name "Install-Aloevera"
if ($module) {
    Write-Host " [OK]" -ForegroundColor Green
    Write-Host "    Version: $($module.Version)" -ForegroundColor Gray
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    exit 1
}

# Check exported functions
Write-Host "[3/5] Checking exported functions..." -NoNewline
$expectedFunctions = @('Install-Aloevera')
$exportedFunctions = $module.ExportedFunctions.Keys

$allPresent = $true
foreach ($func in $expectedFunctions) {
    if ($exportedFunctions -notcontains $func) {
        $allPresent = $false
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "    Missing function: $func" -ForegroundColor Red
    }
}

if ($allPresent) {
    Write-Host " [OK]" -ForegroundColor Green
    foreach ($func in $expectedFunctions) {
        Write-Host "    - $func" -ForegroundColor Gray
    }
}

# Check aliases
Write-Host "[4/5] Checking aliases..." -NoNewline
$expectedAliases = @('Aloe')
$aliasesPresent = $true

foreach ($alias in $expectedAliases) {
    $aliasCmd = Get-Alias -Name $alias -ErrorAction SilentlyContinue
    if (-not $aliasCmd) {
        $aliasesPresent = $false
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "    Missing alias: $alias" -ForegroundColor Red
    }
}

if ($aliasesPresent) {
    Write-Host " [OK]" -ForegroundColor Green
    foreach ($alias in $expectedAliases) {
        Write-Host "    - $alias" -ForegroundColor Gray
    }
}

# Test Get-Help
Write-Host "[5/5] Testing help system..." -NoNewline
try {
    $help = Get-Help Install-Aloevera -ErrorAction Stop
    if ($help.Synopsis) {
        Write-Host " [OK]" -ForegroundColor Green
        Write-Host "    Synopsis: $($help.Synopsis)" -ForegroundColor Gray
    } else {
        Write-Host " [WARN]" -ForegroundColor Yellow
        Write-Host "    Help available but no synopsis" -ForegroundColor Yellow
    }
} catch {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Module Test Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now use:" -ForegroundColor Yellow
Write-Host "  Aloe" -ForegroundColor Cyan
Write-Host "  Install-Aloevera" -ForegroundColor Cyan
Write-Host ""
