# Get the full path for the output file
$outputFile = Join-Path $PWD.Path "NetworkDiagnostics_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

# Function to format timestamps consistently
function Format-TimeStamp {
    param($TimeStamp)
    if ($TimeStamp) {
        return $TimeStamp.ToString("yyyy-MM-dd HH:mm:ss")
    }
    return "Never"
}

# Create the HTML file with header including dark mode button
@"
<!DOCTYPE html>
<html>
<head>
    <title>Network Resources Diagnostic Report</title>
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

        details:nth-of-type(1) > summary { background-color: #2196F3; }
        details:nth-of-type(2) > summary { background-color: #4CAF50; }
        details:nth-of-type(3) > summary { background-color: #9C27B0; }

        [data-theme="dark"] details:nth-of-type(1) > summary { background-color: #1565C0; }
        [data-theme="dark"] details:nth-of-type(2) > summary { background-color: #2E7D32; }
        [data-theme="dark"] details:nth-of-type(3) > summary { background-color: #6A1B9A; }
        
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
        <h1>Network Resources Diagnostic Report</h1>
"@ | Set-Content $outputFile

try {
    # Network Configuration Section
    @"
    <details>
        <summary>Network Configuration</summary>
        <div>
            <div style="display: grid; grid-template-columns: 1fr; gap: 20px;">
                <div>
                    <h3>Network Adapters</h3>
                    <table>
                        <tr>
                            <th>Name</th>
                            <th>Status</th>
                            <th>IP Address</th>
                            <th>Subnet Mask</th>
                            <th>Gateway</th>
                            <th>DNS Servers</th>
                            <th>Speed</th>
                        </tr>
"@ | Add-Content $outputFile

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $adapters) {
        $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
        $ipv4 = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
        $dnsServers = ($ipConfig.DNSServer | Where-Object { $_.AddressFamily -eq 2 }).ServerAddresses -join ", "
        
        @"
        <tr>
            <td>$($adapter.Name)</td>
            <td>$($adapter.Status)</td>
            <td>$($ipv4.IPAddress)</td>
            <td>$($ipv4.PrefixLength)</td>
            <td>$($ipConfig.IPv4DefaultGateway.NextHop)</td>
            <td>$dnsServers</td>
            <td>$([math]::Round($adapter.LinkSpeed/1000000, 2)) Mbps</td>
        </tr>
"@ | Add-Content $outputFile
    }

    @"
                    </table>
                </div>
                <div>
                    <h3>Network Statistics</h3>
                    <table>
                        <tr>
                            <th>Adapter</th>
                            <th>Bytes Received</th>
                            <th>Bytes Sent</th>
                            <th>Errors In</th>
                            <th>Errors Out</th>
                        </tr>
"@ | Add-Content $outputFile

    foreach ($adapter in $adapters) {
        $stats = $adapter | Get-NetAdapterStatistics
        @"
        <tr>
            <td>$($adapter.Name)</td>
            <td>$([math]::Round($stats.ReceivedBytes/1MB, 2)) MB</td>
            <td>$([math]::Round($stats.SentBytes/1MB, 2)) MB</td>
            <td>$($stats.ReceivedErrors)</td>
            <td>$($stats.OutboundErrors)</td>
        </tr>
"@ | Add-Content $outputFile
    }

    @"
                    </table>
                </div>
            </div>
        </div>
    </details>
"@ | Add-Content $outputFile

    # Printers Section
    @"
    <details>
        <summary>Printers Configuration</summary>
        <div>
            <div>
                <h3>Installed Printers</h3>
                <table>
                    <tr>
                        <th>Name</th>
                        <th>Status</th>
                        <th>Port Name</th>
                        <th>Driver Name</th>
                        <th>Location</th>
                        <th>Shared</th>
                        <th>Share Name</th>
                    </tr>
"@ | Add-Content $outputFile

    $printers = Get-Printer
    foreach ($printer in $printers) {
        $driver = Get-PrinterDriver -Name $printer.DriverName -ErrorAction SilentlyContinue
        @"
        <tr>
            <td>$($printer.Name)</td>
            <td>$($printer.PrinterStatus)</td>
            <td>$($printer.PortName)</td>
            <td>$($printer.DriverName)</td>
            <td>$($printer.Location)</td>
            <td>$($printer.Shared)</td>
            <td>$($printer.ShareName)</td>
        </tr>
"@ | Add-Content $outputFile
    }

    @"
                </table>
                <h3>Printer Ports</h3>
                <table>
                    <tr>
                        <th>Name</th>
                        <th>Description</th>
                        <th>Type</th>
                        <th>Host Address</th>
                    </tr>
"@ | Add-Content $outputFile

    $ports = Get-PrinterPort
    foreach ($port in $ports) {
        @"
        <tr>
            <td>$($port.Name)</td>
            <td>$($port.Description)</td>
            <td>$($port.Type)</td>
            <td>$($port.PrinterHostAddress)</td>
        </tr>
"@ | Add-Content $outputFile
    }

    @"
                </table>
            </div>
        </div>
    </details>
"@ | Add-Content $outputFile

    # Network Shares Section
    @"
    <details>
        <summary>Network Shares</summary>
        <div>
            <div>
                <h3>Local Shares</h3>
                <table>
                    <tr>
                        <th>Name</th>
                        <th>Path</th>
                        <th>Description</th>
                        <th>Type</th>
                    </tr>
"@ | Add-Content $outputFile

    $shares = Get-SmbShare
    foreach ($share in $shares) {
        @"
        <tr>
            <td>$($share.Name)</td>
            <td>$($share.Path)</td>
            <td>$($share.Description)</td>
            <td>$($share.ShareType)</td>
        </tr>
"@ | Add-Content $outputFile
    }

    @"
                </table>
                <h3>Mapped Network Drives</h3>
                <table>
                    <tr>
                        <th>Drive Letter</th>
                        <th>Remote Path</th>
                        <th>Status</th>
                    </tr>
"@ | Add-Content $outputFile

    $mappedDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot }
    foreach ($drive in $mappedDrives) {
        @"
        <tr>
            <td>$($drive.Name):</td>
            <td>$($drive.DisplayRoot)</td>
            <td>$(if (Test-Path $drive.Root) { "Connected" } else { "Disconnected" })</td>
        </tr>
"@ | Add-Content $outputFile
    }

    @"
                </table>
            </div>
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
