
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

$url = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
$downloadPath = "$env:TEMP\platform-tools-latest-windows.zip"
$extractPath = "C:\platform-tools"

function Show-Progress {
    param (
        [string]$Activity,
        [string]$Status
    )
    Write-Host "$Activity - $Status" -ForegroundColor Green
}

function Test-CommandExists {
    param (
        [string]$CommandName
    )
    
    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    return ($null -ne $command)
}

Show-Progress "Preliminary Check" "Checking for existing ADB and Fastboot installations..."
$adbExists = Test-CommandExists "adb"
$fastbootExists = Test-CommandExists "fastboot"

if ($adbExists -or $fastbootExists) {
    Write-Host "`nExisting tools found in your PATH:" -ForegroundColor Yellow
    
    if ($adbExists) {
        $adbPath = (Get-Command -Name "adb").Source
        Write-Host "- ADB found at: $adbPath" -ForegroundColor Yellow
    }
    
    if ($fastbootExists) {
        $fastbootPath = (Get-Command -Name "fastboot").Source
        Write-Host "- Fastboot found at: $fastbootPath" -ForegroundColor Yellow
    }
    
    $confirmation = Read-Host "`nDo you want to continue with installation? This may create duplicate entries. (Y/N)"
    if ($confirmation -notmatch '^[Yy]') {
        Write-Host "Installation cancelled by user." -ForegroundColor Cyan
        Exit 0
    }
}

Show-Progress "Step 1/4" "Downloading Android Platform Tools..."
try {
    Invoke-WebRequest -Uri $url -OutFile $downloadPath
    Show-Progress "Step 1/4" "Download complete."
} catch {
    Write-Host "Error downloading file: $_" -ForegroundColor Red
    Exit 1
}

if (Test-Path -Path $extractPath) {
    Show-Progress "Step 2/4" "Removing existing platform-tools directory..."
    Remove-Item -Path $extractPath -Recurse -Force
}

Show-Progress "Step 2/4" "Creating platform-tools directory..."
New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

Show-Progress "Step 3/4" "Extracting platform tools..."
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, "C:\")
    Show-Progress "Step 3/4" "Extraction complete."
} catch {
    Write-Host "Error extracting archive: $_" -ForegroundColor Red
    Exit 1
}

Show-Progress "Step 4/4" "Adding platform-tools to PATH environment variable..."
try {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    
    if ($currentPath -notlike "*$extractPath*") {
        $newPath = "$currentPath;$extractPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Show-Progress "Step 4/4" "Successfully added to PATH."
    } else {
        Show-Progress "Step 4/4" "Path already exists in environment variables."
    }
} catch {
    Write-Host "Error updating PATH environment variable: $_" -ForegroundColor Red
    Exit 1
}

Remove-Item -Path $downloadPath -Force

Write-Host "`nInstallation complete! Android Platform Tools have been installed to $extractPath and added to your PATH." -ForegroundColor Cyan
Write-Host "You may need to restart your terminal or applications for the PATH changes to take effect." -ForegroundColor Yellow
Write-Host "To verify installation, open a new command prompt and type 'adb version'" -ForegroundColor Yellow
Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")