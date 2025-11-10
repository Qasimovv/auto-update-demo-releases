$outputFile = "C:\Windows\Temp\app_usage.txt"
$browserHistoryFile = "C:\Windows\Temp\browser_history.txt"

# Function to escape special characters for JSON
function Escape-JsonString {
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputString
    )
    $escapedString = $InputString -replace '\\', '\\\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
    return $escapedString
}

# Function to get the active window information for Windows
function Get-ActiveWindow {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
        [DllImport("user32.dll")]
        public static extern int GetWindowTextLength(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern int GetClassName(IntPtr hWnd, System.Text.StringBuilder text, int count);
    }
"@

    $hwnd = [User32]::GetForegroundWindow()
    if ($hwnd -eq [IntPtr]::Zero) {
        return $null
    }
    $length = [User32]::GetWindowTextLength($hwnd)
    $sb = New-Object System.Text.StringBuilder -ArgumentList $length
    [User32]::GetWindowText($hwnd, $sb, $sb.Capacity + 1) | Out-Null
    $title = $sb.ToString()
    $sb = New-Object System.Text.StringBuilder -ArgumentList 256
    [User32]::GetClassName($hwnd, $sb, $sb.Capacity + 1) | Out-Null
    $className = $sb.ToString()
    return @{ AppName = $className; WindowTitle = $title }
}

# Function to convert WebKit timestamp to Unix timestamp
function Convert-WebKitToUnix {
    param (
        [Parameter(Mandatory=$true)]
        [long]$WebKitTime
    )
    return [math]::Round(($WebKitTime / 1000000) - 11644473600)
}

# Function to get Edge history since start time
function Get-EdgeHistory {
    $dbPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"
    $dbCopy = "C:\Windows\Temp\EdgeHistoryCopy"

    if (Test-Path $dbPath) {
        Copy-Item $dbPath $dbCopy

        $query = @"
        SELECT
            url,
            IFNULL(title, 'null') as title,
            last_visit_time
        FROM
            urls
        WHERE
            last_visit_time > $(( (start_time + 11644473600) * 1000000 ))
        ORDER BY
            last_visit_time DESC;
"@

        $history = & sqlite3.exe -json $dbCopy $query | ConvertFrom-Json
        Remove-Item $dbCopy

        $history | ForEach-Object {
            $_.last_visit_time = Convert-WebKitToUnix $_.last_visit_time
            $_
        } | ConvertTo-Json -Compress
    } else {
        Write-Output "Edge history DB not found at $dbPath" >&2
        return @()
    }
}

# Get active window information
$windowInfo = Get-ActiveWindow
if ($null -eq $windowInfo) {
    $appUsage = @{
        app_name = "null"
        window_title = "null"
    }
} else {
    $appUsage = @{
        app_name = (Escape-JsonString -InputString $windowInfo.AppName)
        window_title = (Escape-JsonString -InputString $windowInfo.WindowTitle)
    }
}

# Convert to JSON
$json = $appUsage | ConvertTo-Json

# Get Edge browser history
$edgeHistory = Get-EdgeHistory

# Save to file
$json | Out-File -FilePath $outputFile -Encoding UTF8
"edge=$edgeHistory" | Out-File -FilePath $browserHistoryFile -Encoding UTF8

# Output the content of the file
Get-Content -Path $outputFile
Get-Content -Path $browserHistoryFile
