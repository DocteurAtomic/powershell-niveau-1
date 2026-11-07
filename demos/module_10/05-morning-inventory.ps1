<#
.SYNOPSIS
Writes the morning inventory of every instance of the team, as an HTML page.

.DESCRIPTION
Reads the inventory (data/instances.csv), connects to each instance with the sql-lab
secret of the PachaOps vault, and writes one HTML page with two tables: the instances
(status, version, edition, number of databases), and the last full backup of each
database with its age. An instance that does not answer is written "Unreachable", with a
warning, instead of being left out. A database never backed up in full is "never", one
whose last full backup is older than -MaxBackupAgeHours is "late".

The age is computed from the clock of the instance, not from the clock of this computer:
in the lab, the containers run in UTC.

Returns one summary object. The page is written with UTF-8 encoding.

.PARAMETER InventoryPath
The CSV inventory, with the columns Name, SqlInstance and Environment.

.PARAMETER Path
The HTML file to write.

.PARAMETER MaxBackupAgeHours
Age, in hours, beyond which a full backup is late.

.PARAMETER ConnectTimeout
Seconds to wait for each instance before calling it unreachable.

.EXAMPLE
./demos/module_10/05-morning-inventory.ps1

.EXAMPLE
./demos/module_10/05-morning-inventory.ps1 -InventoryPath data/instances.csv -Path lab/inventory.html -Verbose
#>
[CmdletBinding()]
param(
    [string] $InventoryPath = 'data/instances.csv',
    [string] $Path = 'lab/morning-inventory.html',
    [ValidateRange(1, 720)]
    [int] $MaxBackupAgeHours = 24,
    [ValidateRange(1, 60)]
    [int] $ConnectTimeout = 5
)
$ErrorActionPreference = 'Stop'

$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$inventory = Import-Csv -Path $InventoryPath

# One connection per instance. An instance that does not answer stops only its own attempt.
$connections = foreach ($entry in $inventory) {
    try {
        $server = Connect-DbaInstance -SqlInstance $entry.SqlInstance -SqlCredential $cred -ConnectTimeout $ConnectTimeout
        Write-Verbose -Message "$($entry.Name) answers: SQL Server $($server.VersionString)"
        [pscustomobject]@{ Entry = $entry; Server = $server; Error = $null }
    }
    catch {
        Write-Warning -Message "$($entry.Name) ($($entry.SqlInstance)) is unreachable: $($_.Exception.Message)"
        [pscustomobject]@{ Entry = $entry; Server = $null; Error = $_.Exception.Message }
    }
}

$instances = foreach ($connection in $connections) {
    $entry = $connection.Entry
    if ($null -eq $connection.Server) {
        [pscustomobject]@{
            Name = $entry.Name; SqlInstance = $entry.SqlInstance; Environment = $entry.Environment
            Status = 'Unreachable'; Build = ''; Edition = ''; Databases = ''
        }
        continue
    }
    $build = Get-DbaBuild -SqlInstance $connection.Server
    [pscustomobject]@{
        Name        = $entry.Name
        SqlInstance = $entry.SqlInstance
        Environment = $entry.Environment
        Status      = 'OK'
        Build       = "$($connection.Server.VersionString) ($($build.NameLevel) $($build.CULevel))"
        Edition     = $connection.Server.Edition
        Databases   = $connection.Server.Databases.Count
    }
}

$backups = foreach ($connection in $connections | Where-Object -Property Server -NE -Value $null) {
    # The clock of the instance: msdb writes backup dates in the time zone of the server.
    $now = (Invoke-DbaQuery -SqlInstance $connection.Server -Query 'SELECT SYSDATETIME() AS Now;').Now
    foreach ($backup in Get-DbaLastBackup -SqlInstance $connection.Server) {
        $age = if ($null -eq $backup.LastFullBackup) { $null } else { [math]::Round(($now - $backup.LastFullBackup).TotalHours, 1) }
        [pscustomobject]@{
            Instance       = $connection.Entry.Name
            Database       = $backup.Database
            LastFullBackup = if ($null -eq $backup.LastFullBackup) { '' } else { ([datetime] $backup.LastFullBackup).ToString('yyyy-MM-dd HH:mm') }
            AgeHours       = $age
            BackupStatus   = if ($null -eq $age) { 'never' } elseif ($age -gt $MaxBackupAgeHours) { 'late' } else { 'ok' }
        }
    }
}

$head = @'
<title>Morning inventory</title>
<style>
body { font-family: sans-serif; }
table { border-collapse: collapse; margin-bottom: 1em; }
th, td { border: 1px solid #999; padding: 4px 8px; text-align: left; }
th { background: #eee; }
td.bad { background: #f4c7c3; font-weight: bold; }
</style>
'@
$title = "<h1>Morning inventory, $(Get-Date -Format 'yyyy-MM-dd HH:mm')</h1><h2>Instances</h2>"
$backupTable = $backups | ConvertTo-Html -Fragment -PreContent "<h2>Full backups (late after $MaxBackupAgeHours hours)</h2>"
$page = $instances | ConvertTo-Html -Head $head -PreContent $title -PostContent $backupTable
$page = $page -replace '<td>(Unreachable|never|late)</td>', '<td class="bad">$1</td>'
$page | Out-File -FilePath $Path -Encoding utf8

[pscustomobject]@{
    Instances   = @($instances).Count
    Unreachable = @($instances | Where-Object -Property Status -EQ -Value 'Unreachable').Count
    Databases   = @($backups).Count
    ToCheck     = @($backups | Where-Object -Property BackupStatus -NE -Value 'ok').Count
    Path        = $Path
}
