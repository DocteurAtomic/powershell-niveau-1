# Module 10, clip 10.2: the unreachable instances.
# Run from the root of the clone, one command at a time at the console. The four .example
# names of data/instances.csv do not resolve: each one waits for the connection timeout.

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$inventory = Import-Csv -Path data/instances.csv

# The whole inventory, in one call: four warnings, and the four instances left out.
Measure-Command -Expression { $databases = Get-DbaDatabase -SqlInstance $inventory.SqlInstance -SqlCredential $cred -ExcludeSystem } | Select-Object -Property TotalSeconds
$databases | Group-Object -Property SqlInstance -NoElement

# The connection timeout of dbatools, then a shorter one for this session only.
Get-DbatoolsConfig -FullName sql.connection.timeout | Format-List -Property FullName, Value, Description
Set-DbatoolsConfig -FullName sql.connection.timeout -Value 3
Measure-Command -Expression { Get-DbaDatabase -SqlInstance 'compta01.pachadata.example,1433' -SqlCredential $cred -WarningAction SilentlyContinue } | Select-Object -Property TotalSeconds

# -EnableException turns the warning into an error that stops the whole command.
try { $partial = Get-DbaDatabase -SqlInstance 'localhost,14533', 'elearn01.pachadata.example,1433', 'localhost,14534' -SqlCredential $cred -ExcludeSystem -EnableException } catch { "Stopped: $($_.Exception.Message)" }
$null -eq $partial

# One connection per instance, and one line per instance, reachable or not.
$status = foreach ($entry in $inventory) {
    try {
        $server = Connect-DbaInstance -SqlInstance $entry.SqlInstance -SqlCredential $cred -ConnectTimeout 3
        [pscustomobject]@{ Name = $entry.Name; Status = 'OK'; Version = $server.VersionString; Error = '' }
    }
    catch {
        [pscustomobject]@{ Name = $entry.Name; Status = 'Unreachable'; Version = ''; Error = $_.Exception.Message }
    }
}
$status | Format-Table -Property Name, Status, Version, Error
