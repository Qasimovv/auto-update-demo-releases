param(
    [string]$outputFile = "C:\temp\recent_tabs.txt"
)

# Function to get Edge recent tabs
function Get-EdgeTabs {
    $sessionPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Sessions"
    $dbPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"
    $dbCopy = "C:\temp\edge_history_copy_$(Get-Random)"
    
    try {
        if (Test-Path $sessionPath) {
            Write-Host "Edge session path: $sessionPath"
        } else {
            Write-Host "Edge session path not found at $sessionPath"
        }
        
        if (Test-Path $dbPath) {
            Copy-Item $dbPath $dbCopy -ErrorAction Stop
            $query = "SELECT url, title, last_visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 10"
            
            # Try sqlite3.exe first
            try {
                $edgeTabs = & sqlite3.exe -json $dbCopy $query 2>$null
                if ($edgeTabs -and $edgeTabs -ne "") {
                    Remove-Item $dbCopy -ErrorAction SilentlyContinue
                    return $edgeTabs
                }
            } catch {
                Write-Host "sqlite3.exe not available or failed, trying alternative method"
            }
            
            # Fallback: Try using System.Data.SQLite if available
            try {
                Add-Type -AssemblyName System.Data.SQLite -ErrorAction Stop
                $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$dbCopy")
                $conn.Open()
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = $query
                $reader = $cmd.ExecuteReader()
                
                $results = @()
                while ($reader.Read()) {
                    $results += @{
                        url = $reader["url"].ToString()
                        title = $reader["title"].ToString()
                        last_visit_time = $reader["last_visit_time"].ToString()
                    }
                }
                $reader.Close()
                $conn.Close()
                
                Remove-Item $dbCopy -ErrorAction SilentlyContinue
                return ($results | ConvertTo-Json -Compress)
            } catch {
                Write-Host "System.Data.SQLite not available: $($_.Exception.Message)"
            }
            
            # Final fallback: Return empty but valid JSON
            Remove-Item $dbCopy -ErrorAction SilentlyContinue
            return '[]'
        } else {
            Write-Host "Edge history database not found at $dbPath"
            return '[]'
        }
    } catch {
        Write-Host "Error in Get-EdgeTabs: $($_.Exception.Message)"
        if (Test-Path $dbCopy) {
            Remove-Item $dbCopy -ErrorAction SilentlyContinue
        }
        return '[]'
    }
}

# Function to get Chrome recent tabs
function Get-ChromeTabs {
    $sessionPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Sessions"
    $dbPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
    $dbCopy = "C:\temp\chrome_history_copy_$(Get-Random)"
    
    try {
        if (Test-Path $sessionPath) {
            Write-Host "Chrome session path: $sessionPath"
        } else {
            Write-Host "Chrome session path not found at $sessionPath"
        }
        
        if (Test-Path $dbPath) {
            Copy-Item $dbPath $dbCopy -ErrorAction Stop
            $query = "SELECT url, title, last_visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 10"
            
            # Try sqlite3.exe first
            try {
                $chromeTabs = & sqlite3.exe -json $dbCopy $query 2>$null
                if ($chromeTabs -and $chromeTabs -ne "") {
                    Remove-Item $dbCopy -ErrorAction SilentlyContinue
                    return $chromeTabs
                }
            } catch {
                Write-Host "sqlite3.exe not available or failed, trying alternative method"
            }
            
            # Fallback: Try using System.Data.SQLite if available
            try {
                Add-Type -AssemblyName System.Data.SQLite -ErrorAction Stop
                $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$dbCopy")
                $conn.Open()
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = $query
                $reader = $cmd.ExecuteReader()
                
                $results = @()
                while ($reader.Read()) {
                    $results += @{
                        url = $reader["url"].ToString()
                        title = $reader["title"].ToString()
                        last_visit_time = $reader["last_visit_time"].ToString()
                    }
                }
                $reader.Close()
                $conn.Close()
                
                Remove-Item $dbCopy -ErrorAction SilentlyContinue
                return ($results | ConvertTo-Json -Compress)
            } catch {
                Write-Host "System.Data.SQLite not available: $($_.Exception.Message)"
            }
            
            # Final fallback: Return empty but valid JSON
            Remove-Item $dbCopy -ErrorAction SilentlyContinue
            return '[]'
        } else {
            Write-Host "Chrome history database not found at $dbPath"
            return '[]'
        }
    } catch {
        Write-Host "Error in Get-ChromeTabs: $($_.Exception.Message)"
        if (Test-Path $dbCopy) {
            Remove-Item $dbCopy -ErrorAction SilentlyContinue
        }
        return '[]'
    }
}

# Capture recent tabs and save to file
$tabs = @{
    chrome = (Get-ChromeTabs)
    edge = (Get-EdgeTabs)
}
$tabs | ConvertTo-Json -Compress | Set-Content $outputFile

# Output the content of the text file
Get-Content $outputFile
