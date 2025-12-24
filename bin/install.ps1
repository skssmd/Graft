# Graft Installation Script for Windows
# https://github.com/skssmd/graft

$ErrorActionPreference = "Stop"

# Configuration
$Repo = "skssmd/Graft"
$BinaryName = "graft.exe"
$InstallDir = Join-Path $HOME ".graft\bin"

Write-Host "🚀 Starting Graft installation for Windows..." -ForegroundColor Cyan

# Detect Architecture
$Arch = "amd64"
if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    $Arch = "arm64"
}

# Fetch latest version from GitHub API
Write-Host "🔍 Fetching latest version..." -ForegroundColor Blue
try {
    $Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
    $Version = $Release.tag_name
} catch {
    Write-Host "❌ Error: Could not detect latest version." -ForegroundColor Red
    exit 1
}

# Construct download URL
# Format: Graft_1.0.0_Windows_amd64.zip
$VersionClean = $Version.TrimStart('v')
$ArchiveName = "Graft_$($VersionClean)_Windows_$Arch.zip"
$DownloadUrl = "https://github.com/$Repo/releases/download/$Version/$ArchiveName"

Write-Host "📦 Downloading Graft $Version for Windows ($Arch)..." -ForegroundColor Blue

# Create temporary directory
$TmpDir = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TmpDir | Out-Null

try {
    $ZipPath = Join-Path $TmpDir $ArchiveName
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing

    # Extract
    Write-Host "📂 Extracting..." -ForegroundColor Blue
    Expand-Archive -Path $ZipPath -DestinationPath $TmpDir -Force

    if (-not (Test-Path (Join-Path $TmpDir $BinaryName))) {
        Write-Host "❌ Error: Binary not found in archive." -ForegroundColor Red
        exit 1
    }

    # Install to global path
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    Write-Host "🔧 Installing to $InstallDir..." -ForegroundColor Blue
    Move-Item -Path (Join-Path $TmpDir $BinaryName) -Destination (Join-Path $InstallDir $BinaryName) -Force

    # Add to PATH if not already there
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        Write-Host "📝 Adding $InstallDir to User PATH..." -ForegroundColor Blue
        $NewPath = "$UserPath;$InstallDir"
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
        $env:Path = "$env:Path;$InstallDir" # Update current session
    }

    Write-Host "✨ Graft $Version installed successfully!" -ForegroundColor Green
    Write-Host "📍 Location: $(Join-Path $InstallDir $BinaryName)" -ForegroundColor Cyan
    Write-Host "`nPlease restart your terminal or run: `$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')" -ForegroundColor Yellow
    Write-Host "Then run 'graft --help' to get started." -ForegroundColor Green

} finally {
    if (Test-Path $TmpDir) {
        Remove-Item -Path $TmpDir -Recurse -Force
    }
}
