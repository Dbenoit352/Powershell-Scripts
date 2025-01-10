# Get the full path for the output file
$outputFile = Join-Path $PWD.Path "ShutdownDiagnostics_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

# Function to format timestamps consistently
function Format-TimeStamp {
    param($TimeStamp)
    if ($TimeStamp) {
        return $TimeStamp.ToString("yyyy-MM-dd HH:mm:ss")
    }
    return "Never"
}

# Define restart patterns
$restartPatterns = @(
    'shutdown', 'restart', 'reboot', 'stop', 'halt',
    'poweroff', 'power.off', 'power-off',
    'logoff', 'log-off', 'hibernate', 'sleep', 'suspend',
    'wuauclt', 'UsoClient.exe', 'RestartManager',
    'DeviceSetupManager', 'InitiateSystemShutdown',
    'ExitWindowsEx', 'InitiateSystemShutdownEx',
    '/r', '-r', '/s', '-s', '/f', '-f', '/p', '-p',
    '/g', '-g', '/hybrid', '-hybrid',
    'Restart-Computer', 'Stop-Computer', 'Exit-Windows',
    'Add-Computer.*restart', 'Remove-Computer.*restart',
    'wmic.*shutdown', 'wmic.*reboot', 'wmic.*restart',
    'psshutdown', 'shutdown.exe', 'tsshutdn',
    'GPUpdate.*restart', 'sfc.*restart', 'DISM.*restart',
    'bcdedit.*restart', 'chkdsk.*restart', 'winupdate.*restart',
    'msiexec.*restart', 'setup.*restart',
    'install.*restart', 'update.*restart', 'config.*restart'
)

# Gather all system information
$systemInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
$cpu = Get-CimInstance Win32_Processor
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$network = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
$battery = Get-CimInstance Win32_Battery
$memory = Get-CimInstance Win32_OperatingSystem

# Get top processes by CPU and Memory
$processes = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5

# Create the HTML file with header including dark mode button
@"
<!DOCTYPE html>
<html>
<head>
    <title>System Shutdown Diagnostic Report</title>
    <style>
        :root {
            --bg-color: #f5f5f5;
            --text-color: #2c3e50;
            --section-bg: white;
            --border-color: #3498db;
            --table-stripe: #f8f9fa;
            --success-color: #28a745;
            --warning-color: #ffc107;
        }
        
        [data-theme="dark"] {
            --bg-color: #1a1a1a;
            --text-color: #e0e0e0;
            --section-bg: #2d2d2d;
            --border-color: #3498db;
            --table-stripe: #363636;
            --success-color: #00bc8c;
            --warning-color: #f39c12;
        }

        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 20px;
            background-color: var(--bg-color);
            color: var(--text-color);
            transition: all 0.3s ease;
        }
        
        #theme-toggle {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            background: var(--border-color);
            color: white;
            cursor: pointer;
            font-size: 16px;
            z-index: 1000;
            transition: all 0.3s ease;
        }
        
        #theme-toggle:hover {
            opacity: 0.9;
            transform: scale(1.05);
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: var(--section-bg);
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-top: 60px;
        }
        
        h1, h2, h3 {
            color: var(--text-color);
        }
        
        h1 {
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 10px;
        }

        details {
            margin-bottom: 20px;
            background-color: var(--section-bg);
            border-radius: 4px;
            overflow: hidden;
        }
        
        details > summary {
            padding: 15px;
            cursor: pointer;
            user-select: none;
            list-style: none;
            font-weight: 500;
            color: white;
            position: relative;
        }
        
        details > summary::after {
            content: '+';
            position: absolute;
            right: 20px;
            transition: transform 0.2s ease;
        }
        
        details[open] > summary::after {
            transform: rotate(45deg);
        }
        
        details > summary::-webkit-details-marker {
            display: none;
        }
        
        details > div {
            padding: 20px;
            border-top: 1px solid var(--border-color);
        }

        details:nth-of-type(1) > summary { background-color: #673AB7; } /* Deep Purple */
        details:nth-of-type(2) > summary { background-color: #2196F3; } /* Blue */
        details:nth-of-type(3) > summary { background-color: #4CAF50; } /* Green */
        details:nth-of-type(4) > summary { background-color: #9C27B0; } /* Purple */
        details:nth-of-type(5) > summary { background-color: #FF9800; } /* Orange */
        details:nth-of-type(6) > summary { background-color: #E91E63; } /* Pink */
        details:nth-of-type(7) > summary { background-color: #795548; } /* Brown */
        details:nth-of-type(8) > summary { background-color: #607D8B; } /* Blue Grey */
        details:nth-of-type(9) > summary { background-color: #009688; } /* Teal */

        [data-theme="dark"] details:nth-of-type(1) > summary { background-color: #512DA8; }
        [data-theme="dark"] details:nth-of-type(2) > summary { background-color: #1565C0; }
        [data-theme="dark"] details:nth-of-type(3) > summary { background-color: #2E7D32; }
        [data-theme="dark"] details:nth-of-type(4) > summary { background-color: #6A1B9A; }
        [data-theme="dark"] details:nth-of-type(5) > summary { background-color: #EF6C00; }
        [data-theme="dark"] details:nth-of-type(6) > summary { background-color: #C2185B; }
        [data-theme="dark"] details:nth-of-type(7) > summary { background-color: #5D4037; }
        [data-theme="dark"] details:nth-of-type(8) > summary { background-color: #455A64; }
        [data-theme="dark"] details:nth-of-type(9) > summary { background-color: #00796B; }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }
        
        th {
            background-color: var(--section-bg);
            color: var(--text-color);
        }
        
        tr:nth-child(even) {
            background-color: var(--table-stripe);
        }
        
        pre {
            white-space: pre-wrap;
            word-wrap: break-word;
            background-color: var(--section-bg);
            padding: 15px;
            border-radius: 5px;
            border: 1px solid var(--border-color);
        }

        .warning {
            background-color: #fff3cd;
            border-left-color: var(--warning-color);
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
        }
        
        .success {
            background-color: #d4edda;
            border-left-color: var(--success-color);
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
        }
        
        [data-theme="dark"] .warning {
            background-color: #462c00;
            color: #ffd484;
        }
        
        [data-theme="dark"] .success {
            background-color: #004d1a;
            color: #7df0a3;
        }
    </style>
    <script>
        function toggleTheme() {
            const html = document.documentElement;
            const currentTheme = html.getAttribute('data-theme');
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            html.setAttribute('data-theme', newTheme);
            localStorage.setItem('theme', newTheme);
        }

        document.addEventListener('DOMContentLoaded', () => {
            const savedTheme = localStorage.getItem('theme') || 'light';
            document.documentElement.setAttribute('data-theme', savedTheme);
        });
    </script>
</head>
<body>
    <button id="theme-toggle" onclick="toggleTheme()">Toggle Dark Mode</button>
    <div class="container">
        <h1>System Shutdown Diagnostic Report</h1>
"@ | Set-Content $outputFile

try {
    # Current Status Section
    $bootTime = $systemInfo.LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    $uptimeStr = "{0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    
    @"
    <details>
        <summary>Current Status</summary>
        <div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                <div>
                    <h3>System Uptime</h3>
                    <table>
                        <tr><td><strong>Current Uptime:</strong></td><td>$uptimeStr</td></tr>
                        <tr><td><strong>Last Boot Time:</strong></td><td>$(Format-TimeStamp $bootTime)</td></tr>
                        <tr><td><strong>Boot Session:</strong></td><td>$($systemInfo.NumberOfUsers) user(s) logged in</td></tr>
                    </table>
                </div>
                <div>
                    <h3>Current User</h3>
                    <table>
                        <tr><td><strong>Username:</strong></td><td>$($currentUser.Name)</td></tr>
                        <tr><td><strong>Domain:</strong></td><td>$([System.Environment]::UserDomainName)</td></tr>
                        <tr><td><strong>Logon Server:</strong></td><td>$([System.Environment]::GetEnvironmentVariable('LOGONSERVER'))</td></tr>
                    </table>
                </div>
            </div>
        </div>
    </details>

    <details>
        <summary>Performance Metrics</summary>
        <div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                <div>
                    <h3>CPU & Memory</h3>
                    <table>
                        <tr><td><strong>CPU Name:</strong></td><td>$($cpu.Name)</td></tr>
                        <tr><td><strong>CPU Cores:</strong></td><td>$($cpu.NumberOfCores)</td></tr>
                        <tr><td><strong>Memory Used:</strong></td><td>$([math]::Round(($systemInfo.TotalVisibleMemorySize - $systemInfo.FreePhysicalMemory) / 1MB, 2)) GB / $([math]::Round($systemInfo.TotalVisibleMemorySize / 1MB, 2)) GB</td></tr>
                    </table>
                </div>
                <div>
                    <h3>Disk Usage</h3>
                    <table>
                        <tr><th>Drive</th><th>Free Space</th><th>Total Size</th><th>% Free</th></tr>
                        $(foreach ($disk in $disks) {
                            $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
                            $totalSize = [math]::Round($disk.Size / 1GB, 2)
                            $percentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
                            "<tr><td>$($disk.DeviceID)</td><td>${freeSpace} GB</td><td>${totalSize} GB</td><td>${percentFree}%</td></tr>"
                        })
                    </table>
                </div>
            </div>
            <div>
                <h3>Top Processes by Memory</h3>
                <table>
                    <tr><th>Process Name</th><th>Memory Usage (MB)</th><th>CPU Time</th></tr>
                    $(foreach ($process in $processes) {
                        $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
                        "<tr><td>$($process.ProcessName)</td><td>$memoryMB</td><td>$($process.CPU)</td></tr>"
                    })
                </table>
            </div>
        </div>
    </details>

    <details>
        <summary>Network Information</summary>
        <div>
            <div style="display: grid; grid-template-columns: 1fr; gap: 20px;">
                <div>
                    <h3>Network Adapters</h3>
                    <table>
                        <tr><th>Adapter</th><th>IP Address</th><th>Subnet Mask</th><th>Gateway</th>
                        </tr>
                        $(foreach ($adapter in $network) {
                            "<tr><td>$($adapter.Description)</td><td>$($adapter.IPAddress[0])</td><td>$($adapter.IPSubnet[0])</td><td>$($adapter.DefaultIPGateway -join ', ')</td></tr>"
                        })
                    </table>
                </div>
                <div>
                    <h3>DNS Settings</h3>
                    <table>
                        <tr><th>Adapter</th><th>DNS Servers</th></tr>
                        $(foreach ($adapter in $network) {
                            "<tr><td>$($adapter.Description)</td><td>$($adapter.DNSServerSearchOrder -join ', ')</td></tr>"
                        })
                    </table>
                </div>
            </div>
        </div>
    </details>

    <details>
        <summary>System Hardware</summary>
        <div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                <div>
                    <h3>System Information</h3>
                    <table>
                        <tr><td><strong>Manufacturer:</strong></td><td>$($cs.Manufacturer)</td></tr>
                        <tr><td><strong>Model:</strong></td><td>$($cs.Model)</td></tr>
                        <tr><td><strong>BIOS Version:</strong></td><td>$($bios.SMBIOSBIOSVersion)</td></tr>
                        <tr><td><strong>System Type:</strong></td><td>$($cs.SystemType)</td></tr>
                    </table>
                </div>
                <div>
                    <h3>Battery Status</h3>
                    <table>
                        $(if ($battery) {
                            @"
                            <tr><td><strong>Status:</strong></td><td>$($battery.Status)</td></tr>
                            <tr><td><strong>Charge Remaining:</strong></td><td>$($battery.EstimatedChargeRemaining)%</td></tr>
                            <tr><td><strong>Battery Type:</strong></td><td>$($battery.Chemistry)</td></tr>
"@
                        } else {
                            "<tr><td colspan='2'>No battery detected (Desktop PC)</td></tr>"
                        })
                    </table>
                </div>
            </div>
        </div>
    </details>

    <details>
        <summary>Scheduled Tasks That Can Trigger Restarts</summary>
        <div>
"@  | Add-Content $outputFile

    # Scheduled Tasks Section
    $matchingTasks = Get-ScheduledTask -ErrorAction Stop | Where-Object { $_.TaskName -match ($restartPatterns -join '|') } | ForEach-Object {
        $taskInfo = Get-ScheduledTaskInfo -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue
        @{
            Name = $_.TaskName
            Description = if ($_.Description) { $_.Description } else { "N/A" }
            State = if ($_.State) { $_.State } else { "N/A" }
            Author = if ($_.Author) { $_.Author } else { "N/A" }
            LastRun = if ($taskInfo.LastRunTime) { Format-TimeStamp $taskInfo.LastRunTime } else { "Never" }
            RunLevel = if ($_.Principal.RunLevel) { $_.Principal.RunLevel } else { "N/A" }
            UserId = if ($_.Principal.UserId) { $_.Principal.UserId } else { "N/A" }
        }
    }

    if ($matchingTasks) {
        foreach ($task in $matchingTasks) {
            @"
            <div class='task-entry'>
                <h3 style='border-bottom: 2px solid #3498db; padding-bottom: 5px;'>Task: $($task.Name)</h3>
                <table>
                    <tr><td><strong>Description:</strong></td><td>$($task.Description)</td></tr>
                    <tr><td><strong>State:</strong></td><td>$($task.State)</td></tr>
                    <tr><td><strong>Author:</strong></td><td>$($task.Author)</td></tr>
                    <tr><td><strong>Last Run:</strong></td><td>$($task.LastRun)</td></tr>
                    <tr><td><strong>Security Context:</strong></td><td>$($task.UserId)</td></tr>
                    <tr><td><strong>Run Level:</strong></td><td>$($task.RunLevel)</td></tr>
                </table>
            </div>
            <hr style='border: none; border-top: 1px solid #ddd; margin: 20px 0;'>
"@ | Add-Content $outputFile
        }
    } else {
        "<p class='success'>No restart-related scheduled tasks found.</p>" | Add-Content $outputFile
    }

    "</div></details>" | Add-Content $outputFile

    # Recent Shutdown Events Section
    @"
    <details>
        <summary>Recent Shutdown Events</summary>
        <div>
            <table>
                <tr>
                    <th>Time</th>
                    <th>Event Type</th>
                    <th>ID</th>
                    <th>Details</th>
                </tr>
"@ | Add-Content $outputFile

    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Id = 41, 1074, 1076, 6006, 6008
        StartTime = (Get-Date).AddDays(-7)
    } -ErrorAction SilentlyContinue | Select-Object -First 10

    foreach ($event in $events) {
        $eventType = switch ($event.Id) {
            41 {"Critical Shutdown"}
            1074 {"User Initiated"}
            1076 {"Unexpected"}
            6006 {"Clean Shutdown"}
            6008 {"Unclean Shutdown"}
            default {"Unknown"}
        }
        @"
            <tr>
                <td>$($event.TimeCreated)</td>
                <td>$eventType</td>
                <td>$($event.Id)</td>
                <td>$($event.Message)</td>
            </tr>
"@ | Add-Content $outputFile
    }

    @"
            </table>
        </div>
    </details>
"@ | Add-Content $outputFile

    # Restart Status Section
    @"
    <details>
        <summary>Restart Status Check</summary>
        <div class='section'>
"@ | Add-Content $outputFile

    $restartChecks = @{
        "Windows Update" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        "SCCM Client" = "HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData"
        "File Rename Operations" = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\FileRenameOperations"
        "Computer Name Change" = "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName"
        "Component Based Servicing" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    }

    foreach ($check in $restartChecks.GetEnumerator()) {
        if (Test-Path $check.Value) {
            "<p class='warning'>&times; $($check.Key) indicates a pending restart</p>" | Add-Content $outputFile
        } else {
            "<p class='success'>&check; $($check.Key) shows no pending restart</p>" | Add-Content $outputFile
        }
    }

    @"
        </div>
    </details>
"@ | Add-Content $outputFile

} catch {
    @"
    <div class='section'>
        <h2>Error</h2>
        <p class='warning'>An error occurred while generating the report: $($_.Exception.Message)</p>
    </div>
"@ | Add-Content $outputFile
}

# Close HTML
@"
    </div>
</body>
</html>
"@ | Add-Content $outputFile

# Open the report
if (Test-Path $outputFile) {
    Invoke-Item $outputFile
}
