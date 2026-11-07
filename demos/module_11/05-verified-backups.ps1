<#
.SYNOPSIS
Backs up every user database of the lab, and proves that each backup restores on the other instance.

.DESCRIPTION
For each instance of -SqlInstance, takes a full, compressed backup of every user database
into -BackupFolder, a folder that both instances can read (in the lab, the shared volume
/var/opt/mssql/backup). Then restores each backup on the other instance under the name
m11_test_<database> with Test-DbaLastBackup -Path, runs DBCC CHECKDB on the copy, and drops it.

Returns one object per database. Verified is $true only when the restore and DBCC CHECKDB
both returned Success: Test-DbaLastBackup reports a test it did not run as "Skipped",
without an error, so the result is read property by property. The script writes a warning
for each backup that is not verified, and ends with exit code 1 when there is one.

The backups stay in -BackupFolder: they are the backups of the team. In the lab,
./demos/module_11/99-cleanup.ps1 removes them.

.PARAMETER SqlInstance
The instances to back up. Each backup is tested on the next instance of the list.

.PARAMETER ExcludeDatabase
User databases to leave out.

.PARAMETER BackupFolder
The folder of the backups, as the instances see it.

.EXAMPLE
./demos/module_11/05-verified-backups.ps1 | Format-Table

.EXAMPLE
./demos/module_11/05-verified-backups.ps1 -ExcludeDatabase PachadataTraining -Verbose
#>
[CmdletBinding()]
param(
    [ValidateCount(2, 16)]
    [string[]] $SqlInstance = ('localhost,14533', 'localhost,14534'),
    [string[]] $ExcludeDatabase,
    [string] $BackupFolder = '/var/opt/mssql/backup'
)
$ErrorActionPreference = 'Stop'

$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

$failed = 0
for ($i = 0; $i -lt $SqlInstance.Count; $i++) {
    $instance = $SqlInstance[$i]
    $destination = $SqlInstance[($i + 1) % $SqlInstance.Count]
    $databases = Get-DbaDatabase -SqlInstance $instance -SqlCredential $cred -ExcludeSystem -ExcludeDatabase $ExcludeDatabase -EnableException
    foreach ($database in $databases) {
        Write-Verbose -Message "Backing up $($database.Name) on $instance, testing on $destination"
        # The name of the instance in the file, so that two databases of the same name do not meet.
        $name = "m11_$($database.SqlInstance)_dbname_backuptype_timestamp.bak"
        $backup = $database | Backup-DbaDatabase -Type Full -CompressBackup -Path $BackupFolder -FilePath $name -ReplaceInName -EnableException
        $test = Test-DbaLastBackup -Path $backup.BackupPath -Destination $destination -DestinationSqlCredential $cred -Prefix m11_test_
        $verified = $test.RestoreResult -eq 'Success' -and $test.DbccResult -eq 'Success'
        if (-not $verified) {
            $failed++
            Write-Warning -Message "$($database.Name) on ${instance}: restore $($test.RestoreResult), DBCC $($test.DbccResult)"
        }
        [pscustomobject]@{
            Instance     = $database.SqlInstance
            Database     = $database.Name
            TestedOn     = $destination
            BackupFile   = $backup.BackupPath
            CompressedMB = [math]::Round($backup.CompressedBackupSize.Megabyte, 1)
            Restore      = $test.RestoreResult
            Dbcc         = $test.DbccResult
            Verified     = $verified
        }
    }
}
if ($failed -gt 0) { exit 1 }
