if (!(Test-Path "C:\ProgramData\chocolatey\choco.exe")) {
    Write-Host "Chocolatey is not installed. Installing now..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

Write-Host "Installing Google Chrome..."
choco install googlechrome -y --ignore-checksums --force

Start-Sleep -Seconds 10

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

$scriptUrl = "https://raw.githubusercontent.com/DanysysTeam/PS-SFTA/master/SFTA.ps1"
Invoke-Expression (Invoke-WebRequest -Uri $scriptUrl -UseBasicP).Content

Write-Host "Setting Google Chrome as the default application for .url and .html file types..."
Set-FTA "ChromeHTML" ".url"
Set-FTA "ChromeHTML" ".html"

Write-Host "Google Chrome has been set as the default application for .url and .html files."
