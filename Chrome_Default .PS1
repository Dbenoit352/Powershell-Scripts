# Ensure Chocolatey is installed
if (!(Test-Path "C:\ProgramData\chocolatey\choco.exe")) {
    Write-Host "Chocolatey is not installed. Installing now..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install Google Chrome silently
Write-Host "Installing Google Chrome..."
choco install googlechrome -y --ignore-checksums --force

# Wait for installation to complete
Start-Sleep -Seconds 10

# Path to the Chrome executable
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Register Google Chrome as the default application for .url and .html file types
Write-Host "Setting Google Chrome as the default application for .url and .html file types..."
Register-FTA $chromePath ".url"
Register-FTA $chromePath ".html"

Write-Host "Google Chrome has been set as the default application for .url and .html files."
