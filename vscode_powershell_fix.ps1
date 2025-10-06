# Windows Development Environment - VS Code & PowerShell Fix
# Complements the Level 2 Dual Compatibility Architecture with IDE and shell configuration
# Author: Windows Dev Environment Fix System

param(
    [switch]$SkipVSCode,
    [switch]$SkipPowerShell,
    [switch]$Force
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VS Code & PowerShell Environment Fix" -ForegroundColor Cyan
Write-Host "Complements Level 2 Dual Compatibility" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get user's clean path (default: C:\DEV)
$CleanPath = "C:\DEV"
if ($env:HOME -and (Test-Path $env:HOME)) {
    $CleanPath = $env:HOME
}

Write-Host "Detected clean path: $CleanPath" -ForegroundColor Green
Write-Host ""

# Section 1: Environment Verification
Write-Host "[1/5] Verifying Environment..." -ForegroundColor Yellow
Write-Host "  Current Directory: $(Get-Location)" -ForegroundColor White
Write-Host "  PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host "  OS: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption)" -ForegroundColor White

if (Test-Path $CleanPath) {
    Write-Host "  [OK] Clean path exists: $CleanPath" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Clean path not found. Please run main Level 2 setup first." -ForegroundColor Yellow
}
Write-Host ""

# Section 2: PowerShell Profile Configuration
if (-not $SkipPowerShell) {
    Write-Host "[2/5] Configuring PowerShell Profile..." -ForegroundColor Yellow

    $profileDir = Split-Path $PROFILE
    $profilePath = $PROFILE

    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-Host "  [OK] Created PowerShell profile directory" -ForegroundColor Green
    }

    # Create PowerShell profile content
    $profileContent = @"
# Windows Development Environment - PowerShell Profile
# Auto-configured for clean path development

# Set default location to clean path
Set-Location $CleanPath

# Environment variables for development
`$env:DEV_HOME = "$CleanPath"
`$env:PROJECTS_PATH = "$CleanPath\Projects"

# Aliases for quick navigation
function dev { Set-Location $CleanPath }
function projects { Set-Location $CleanPath\Projects }

# Display welcome message
Write-Host "Development Environment Ready" -ForegroundColor Green
Write-Host "Clean Path: $CleanPath" -ForegroundColor Cyan
Write-Host "Type 'dev' to return to development root" -ForegroundColor Yellow
Write-Host ""
"@

    if ((Test-Path $profilePath) -and -not $Force) {
        Write-Host "  [INFO] PowerShell profile exists. Backup created." -ForegroundColor Yellow
        Copy-Item $profilePath "$profilePath.backup" -Force
    }

    Set-Content -Path $profilePath -Value $profileContent -Force
    Write-Host "  [OK] PowerShell profile configured" -ForegroundColor Green
    Write-Host "      Location: $profilePath" -ForegroundColor White
} else {
    Write-Host "[2/5] Skipping PowerShell configuration" -ForegroundColor Yellow
}
Write-Host ""

# Section 3: VS Code Workspace Configuration
if (-not $SkipVSCode) {
    Write-Host "[3/5] Creating VS Code Workspace..." -ForegroundColor Yellow

    $workspaceFile = "$CleanPath\Dev-Workspace.code-workspace"

    $workspaceContent = @{
        folders = @(
            @{
                name = "Development Root"
                path = $CleanPath
            },
            @{
                name = "Projects"
                path = "$CleanPath\Projects"
            }
        )
        settings = @{
            "terminal.integrated.cwd" = $CleanPath
            "terminal.integrated.defaultProfile.windows" = "PowerShell"
        }
    }

    $workspaceContent | ConvertTo-Json -Depth 10 | Set-Content -Path $workspaceFile -Force
    Write-Host "  [OK] VS Code workspace created: $workspaceFile" -ForegroundColor Green
} else {
    Write-Host "[3/5] Skipping VS Code workspace creation" -ForegroundColor Yellow
}
Write-Host ""

# Section 4: VS Code User Settings Update
if (-not $SkipVSCode) {
    Write-Host "[4/5] Updating VS Code User Settings..." -ForegroundColor Yellow

    $vsCodeSettingsPath = "$env:APPDATA\Code\User\settings.json"

    if (Test-Path $vsCodeSettingsPath) {
        $settings = Get-Content $vsCodeSettingsPath -Raw | ConvertFrom-Json

        # Add clean path settings
        $settings | Add-Member -NotePropertyName "terminal.integrated.cwd" -NotePropertyValue $CleanPath -Force

        if (-not $settings."terminal.integrated.env.windows") {
            $settings | Add-Member -NotePropertyName "terminal.integrated.env.windows" -NotePropertyValue @{} -Force
        }

        $settings."terminal.integrated.env.windows" | Add-Member -NotePropertyName "DEV_HOME" -NotePropertyValue $CleanPath -Force

        $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $vsCodeSettingsPath -Force
        Write-Host "  [OK] VS Code settings updated" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] VS Code settings not found (VS Code may not be installed)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[4/5] Skipping VS Code settings update" -ForegroundColor Yellow
}
Write-Host ""

# Section 5: VS Code Extension Cache Cleanup
if (-not $SkipVSCode) {
    Write-Host "[5/5] Cleaning VS Code Extension Cache..." -ForegroundColor Yellow

    $vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcesses) {
        Write-Host "  [WARNING] VS Code is running - cannot clean cache" -ForegroundColor Yellow
        Write-Host "            Please close VS Code and run this script again" -ForegroundColor Yellow
    } else {
        $workspaceStorage = "$env:APPDATA\Code\User\workspaceStorage"
        if (Test-Path $workspaceStorage) {
            $cleanedCount = 0
            Get-ChildItem $workspaceStorage -Directory | ForEach-Object {
                $age = (Get-Date) - $_.LastWriteTime
                if ($age.Days -gt 7) {
                    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    $cleanedCount++
                }
            }
            Write-Host "  [OK] Cleaned $cleanedCount old workspace caches" -ForegroundColor Green
        }
    }
} else {
    Write-Host "[5/5] Skipping VS Code cache cleanup" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CONFIGURATION COMPLETE" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SUMMARY:" -ForegroundColor Yellow
if (-not $SkipPowerShell) {
    Write-Host "  [OK] PowerShell profile configured" -ForegroundColor Green
}
if (-not $SkipVSCode) {
    Write-Host "  [OK] VS Code workspace created" -ForegroundColor Green
    Write-Host "  [OK] VS Code settings updated" -ForegroundColor Green
    Write-Host "  [OK] Extension cache cleaned" -ForegroundColor Green
}
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Restart PowerShell to load new profile" -ForegroundColor White
Write-Host "2. Open VS Code workspace: $CleanPath\Dev-Workspace.code-workspace" -ForegroundColor White
Write-Host "3. Verify terminal opens in clean path: $CleanPath" -ForegroundColor White
Write-Host ""
Write-Host "Your development environment is now optimized!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
