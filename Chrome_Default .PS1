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

# Create the default app association XML file
$xmlPath = "$env:TEMP\chrome_association.xml"
$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
    <Association Identifier=".htm" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
    <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
    <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
    <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
"@
$xmlContent | Set-Content -Path $xmlPath -Encoding UTF8

# Apply the default app associations using DISM
Write-Host "Setting Google Chrome as the default browser..."
Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Import-DefaultAppAssociations:$xmlPath" -Wait -NoNewWindow

Write-Host "Google Chrome has been set as the default browser."
