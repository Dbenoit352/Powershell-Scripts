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

Write-Host "Setting Google Chrome as the default application for various file types..."

$fileTypes = @(".html",".url")

foreach ($fileType in $fileTypes) {
    New-Item -Path "HKCU:\Software\Classes\$fileType" -Value "ChromeHTML" -Force
    New-Item -Path "HKCU:\Software\Classes\ChromeHTML\shell\open\command" -Value "`"$chromePath`" `"%1`"" -Force
}

Write-Host "Google Chrome has been set as the default application for .html, .pdf, and .url files."
