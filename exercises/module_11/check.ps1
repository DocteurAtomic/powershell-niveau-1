<#
.SYNOPSIS
Checks the exercise of module 11.

.DESCRIPTION
Reads the secret sql-lab in the vault PachaOps, checks that the database Finance of
./demos/module_10/00-setup.ps1 exists on sql2, then loads Test-BackupRestore.ps1 and runs the
function twice, with the copy name m11_check_copy:

1. with -WhatIf: no backup of Finance may appear in the history of sql2, no restore in the
   history of sql1, and no database m11_check_copy;
2. for real: the object returned must give the row count of dbo.LedgerEntry in Finance (the
   check counts it too), the same count for the copy, RowsMatch $true and CopyRemoved $true;
   the history of sql2 must show the backup in BackupFile, the history of sql1 a restore of
   m11_check_copy, and the copy must be gone.

The function must not contain the lab password. At the end, removes what the function created:
the copy if it is left, the backup files written by the check runs and their history on both
instances. Exits with 0 when everything is right, 1 otherwise, and says what is missing. With
-Solution, checks the file of the solution folder.

.EXAMPLE
./exercises/module_11/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your file.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$script = Join-Path $folder 'Test-BackupRestore.ps1'
$name = 'Test-BackupRestore'
$problems = [System.Collections.Generic.List[string]]::new()
$sql1 = 'localhost,14533'
$sql2 = 'localhost,14534'
$copy = 'm11_check_copy'

$syntaxErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref] $null, [ref] $syntaxErrors)
if ($syntaxErrors) {
    "FAIL  Test-BackupRestore.ps1: PowerShell cannot read it, line $($syntaxErrors[0].Extent.StartLineNumber): $($syntaxErrors[0].Message)"
    exit 1
}

$cred = try { Get-Secret -Name sql-lab -Vault PachaOps -WarningAction SilentlyContinue } catch { $null }
if ($cred -isnot [pscredential]) {
    'FAIL  the secret sql-lab cannot be read in the vault PachaOps: create it as in clip 9.1, or run ./demos/module_09/00-setup.ps1.'
    exit 1
}
if ((Get-Content -Path $script -Raw).Contains($cred.GetNetworkCredential().Password)) {
    $problems.Add("Test-BackupRestore.ps1 contains the lab password: read it in the vault, with Get-Secret.")
}

Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
if (-not (Get-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database Finance -EnableException)) {
    'FAIL  the database Finance is missing on sql2 (localhost,14534): run ./demos/module_10/00-setup.ps1.'
    exit 1
}
if (Get-DbaDatabase -SqlInstance $sql1 -SqlCredential $cred -Database $copy -EnableException) {
    "FAIL  the database $copy already exists on sql1, left by an earlier run: ./demos/module_11/99-cleanup.ps1 removes it."
    exit 1
}
$expectedRows = (Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Database Finance -Query 'SELECT COUNT_BIG(*) AS Rows FROM dbo.LedgerEntry;' -EnableException).Rows

# What the runs leave in msdb, read from the clock of each instance (they run in UTC). msdb
# writes the dates of the history to the second, rounded down: one second of margin.
$clock = 'SELECT DATEADD(second, -1, SYSDATETIME()) AS Now;'
$start2 = (Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Query $clock -EnableException).Now
$start1 = (Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Query $clock -EnableException).Now
$newBackups = @'
SELECT f.physical_device_name AS Path
FROM msdb.dbo.backupset AS b
JOIN msdb.dbo.backupmediafamily AS f ON f.media_set_id = b.media_set_id
WHERE b.database_name = N'Finance' AND b.backup_start_date >= @start;
'@
$newRestores = @'
SELECT COUNT(*) AS Restores FROM msdb.dbo.restorehistory
WHERE destination_database_name = @copy AND restore_date >= @start;
'@
function Get-CheckState {
    [pscustomobject]@{
        Backups  = @(Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Query $newBackups -SqlParameter @{ start = $start2 } -EnableException |
            Select-Object -ExpandProperty Path)
        Restores = (Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Query $newRestores -SqlParameter @{ copy = $copy; start = $start1 } -EnableException).Restores
        Copy     = [bool](Get-DbaDatabase -SqlInstance $sql1 -SqlCredential $cred -Database $copy -EnableException)
    }
}

try {
    . $script
    $command = Get-Command -Name $name -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        "FAIL  Test-BackupRestore.ps1 does not define the function $name."
        exit 1
    }

    # 1. -WhatIf: nothing may happen.
    if (-not $command.Parameters.ContainsKey('WhatIf')) {
        $problems.Add("${name} does not accept -WhatIf: add SupportsShouldProcess to [CmdletBinding()].")
    }
    else {
        try {
            $null = & $name -SqlCredential $cred -CopyName $copy -WhatIf -WarningAction SilentlyContinue
        }
        catch {
            $problems.Add("${name} -WhatIf stopped: $($_.Exception.Message)")
        }
        $state = Get-CheckState
        if ($state.Backups.Count -gt 0) {
            $problems.Add("${name} -WhatIf backed up Finance ($($state.Backups -join ', ')): -WhatIf does not reach the dbatools commands by itself; ask `$PSCmdlet.ShouldProcess before the backup, or pass -WhatIf:`$WhatIfPreference.")
        }
        if ($state.Restores -gt 0 -or $state.Copy) {
            $problems.Add("${name} -WhatIf restored $copy on sql1: nothing may be restored with -WhatIf.")
        }
    }

    # 2. For real.
    $parameters = @{ SqlCredential = $cred; CopyName = $copy; WarningAction = 'SilentlyContinue' }
    if ($command.Parameters.ContainsKey('Confirm')) { $parameters.Confirm = $false }
    $whatIfBackups = (Get-CheckState).Backups.Count
    $rows = try {
        @(& $name @parameters)
    }
    catch {
        $problems.Add("${name} stopped: $($_.Exception.Message)")
        @()
    }
    $state = Get-CheckState
    if ($rows.Count -ne 1) {
        $problems.Add("${name} returned $($rows.Count) object(s), expected one.")
    }
    else {
        $row = $rows[0]
        foreach ($property in 'Database', 'Copy', 'Destination', 'BackupFile', 'SourceRows', 'CopyRows', 'RowsMatch', 'CopyRemoved') {
            if ($null -eq $row.PSObject.Properties[$property]) {
                $problems.Add("${name}: the property $property is missing.")
            }
        }
        if ($row.SourceRows -ne $expectedRows) {
            $problems.Add("${name}: SourceRows is '$($row.SourceRows)', expected $expectedRows, the rows of dbo.LedgerEntry in Finance.")
        }
        if ($row.CopyRows -ne $expectedRows) {
            $problems.Add("${name}: CopyRows is '$($row.CopyRows)', expected $expectedRows, the rows of dbo.LedgerEntry in the copy.")
        }
        if ($row.RowsMatch -isnot [bool] -or -not $row.RowsMatch) {
            $problems.Add("${name}: RowsMatch is '$($row.RowsMatch)', expected the boolean `$true.")
        }
        if ($row.CopyRemoved -isnot [bool] -or -not $row.CopyRemoved) {
            $problems.Add("${name}: CopyRemoved is '$($row.CopyRemoved)', expected the boolean `$true.")
        }
        if ($state.Backups.Count -le $whatIfBackups) {
            $problems.Add("${name}: no new backup of Finance in the history of sql2.")
        }
        elseif ([string] $row.BackupFile -notin $state.Backups) {
            $problems.Add("${name}: BackupFile is '$($row.BackupFile)', which is not the file of the new backup of Finance ($($state.Backups -join ', ')).")
        }
        elseif ((Split-Path -Path ([string] $row.BackupFile) -Leaf) -notlike 'm11_*') {
            $problems.Add("${name}: the name of the backup file must start with m11_, so that ./demos/module_11/99-cleanup.ps1 finds it.")
        }
    }
    if ($state.Restores -lt 1) {
        $problems.Add("${name}: no restore of $copy in the history of sql1.")
    }
    if ($state.Copy) {
        $problems.Add("${name}: the copy $copy is still on sql1: drop it at the end (Remove-DbaDatabase -Confirm:`$false).")
    }
}
finally {
    # What the runs created: the copy, the backup files and their history on both instances.
    $state = try { Get-CheckState } catch { $null }
    if ($state.Copy) {
        Remove-DbaDatabase -SqlInstance $sql1 -SqlCredential $cred -Database $copy -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
    }
    $history = @'
DECLARE @sets TABLE (backup_set_id int PRIMARY KEY, media_set_id int);
INSERT INTO @sets (backup_set_id, media_set_id)
SELECT DISTINCT b.backup_set_id, b.media_set_id
FROM msdb.dbo.backupset AS b
JOIN msdb.dbo.backupmediafamily AS f ON f.media_set_id = b.media_set_id
WHERE f.physical_device_name = @path;
DECLARE @restores TABLE (restore_history_id int PRIMARY KEY);
INSERT INTO @restores (restore_history_id)
SELECT restore_history_id FROM msdb.dbo.restorehistory WHERE backup_set_id IN (SELECT backup_set_id FROM @sets);
DELETE FROM msdb.dbo.restorefile WHERE restore_history_id IN (SELECT restore_history_id FROM @restores);
DELETE FROM msdb.dbo.restorefilegroup WHERE restore_history_id IN (SELECT restore_history_id FROM @restores);
DELETE FROM msdb.dbo.restorehistory WHERE restore_history_id IN (SELECT restore_history_id FROM @restores);
DELETE FROM msdb.dbo.backupfile WHERE backup_set_id IN (SELECT backup_set_id FROM @sets);
DELETE FROM msdb.dbo.backupfilegroup WHERE backup_set_id IN (SELECT backup_set_id FROM @sets);
DELETE FROM msdb.dbo.backupset WHERE backup_set_id IN (SELECT backup_set_id FROM @sets);
DELETE FROM msdb.dbo.backupmediafamily WHERE media_set_id IN (SELECT media_set_id FROM @sets);
DELETE FROM msdb.dbo.backupmediaset WHERE media_set_id IN (SELECT media_set_id FROM @sets);
'@
    foreach ($path in @($state.Backups)) {
        if (-not $path) { continue }
        foreach ($instance in $sql1, $sql2) {
            Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query $history -SqlParameter @{ path = $path } `
                -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
        Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Query 'EXEC master.sys.xp_delete_files @path;' -SqlParameter @{ path = $path } `
            -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object -Process { "FAIL  $_" }
    exit 1
}
'OK    module 11: Test-BackupRestore does nothing with -WhatIf, and restores, compares and drops the copy without it.'
exit 0
