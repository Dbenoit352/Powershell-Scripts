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

# Open the Default Apps settings for the user to set Chrome as default
Write-Host "Opening Default Apps settings..."
Start-Process "ms-settings:defaultapps"

Write-Host "Please set Google Chrome as the default browser in the settings."
