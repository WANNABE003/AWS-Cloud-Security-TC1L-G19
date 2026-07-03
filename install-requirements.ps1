$ErrorActionPreference = "Stop"

$requirementsPath = Join-Path $PSScriptRoot "requirements.txt"

if (-not (Test-Path -LiteralPath $requirementsPath)) {
    throw "requirements.txt was not found beside this installer."
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is required. Install or update Microsoft App Installer, then run this script again."
}

$requirements = Get-Content -LiteralPath $requirementsPath |
    Where-Object { $_.Trim() -and -not $_.Trim().StartsWith("#") }

foreach ($requirement in $requirements) {
    $parts = $requirement.Split("|", 3)
    if ($parts.Count -ne 3) {
        throw "Invalid requirements.txt entry: $requirement"
    }

    $command = $parts[0].Trim()
    $packageId = $parts[1].Trim()
    $displayName = $parts[2].Trim()

    if (Get-Command $command -ErrorAction SilentlyContinue) {
        Write-Host "[OK] $displayName is already installed. Skipping." -ForegroundColor Green
        continue
    }

    Write-Host "[INSTALL] Installing $displayName..." -ForegroundColor Cyan
    & winget install --id $packageId --exact --accept-source-agreements --accept-package-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "Installation failed for $displayName (winget exit code $LASTEXITCODE)."
    }
}

Write-Host "Requirements check completed." -ForegroundColor Green
Write-Host "Close and reopen PowerShell before continuing so newly installed commands are available."
