<#
.SYNOPSIS
Checks the exercise of module 12.

.DESCRIPTION
Two parts.

The move. Reads the secrets sql-lab and finance-report in the vault PachaOps, checks that
./demos/module_12/00-setup.ps1 has run (the database Finance and the login finance_report on
sql2), removes from sql1 the copy that an earlier run may have left, then runs
Move-FinanceApp.ps1 twice:

1. with -WhatIf: neither the database Finance nor the login finance_report may appear on sql1;
2. for real: Finance must be on sql1, finance_report too with the SID it has on sql2, the
   check must read dbo.LedgerEntry on sql1 connected as finance_report and find the rows of
   sql2, the copy must have no orphaned user, and the object returned must say the same
   (SourceRows, Rows, Orphans, Verified $true).

The script must not contain a password of the lab. At the end, the check removes from sql1
what the script created (the database, the login, the history of the copy).

The schedule. Reads the last line of the trace, lab/nightly-report.csv, written by
./demos/module_12/05-nightly-report.ps1 each time your scheduler runs it: it must be less
than 26 hours old and say exit code 0. With -Solution, the check first runs the script itself,
as a scheduler does: from the home folder, pwsh -NoProfile -NonInteractive -File.

Exits with 0 when everything is right, 1 otherwise, and says what is missing. With -Solution,
checks the file of the solution folder.

.EXAMPLE
./exercises/module_12/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your file, and run the nightly report as a scheduler does.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$script = Join-Path $folder 'Move-FinanceApp.ps1'
$root = (Resolve-Path -Path (Join-Path $PSScriptRoot '..' '..')).Path
$trace = Join-Path $root 'lab' 'nightly-report.csv'
$problems = [System.Collections.Generic.List[string]]::new()
$sql1 = 'localhost,14533'
$sql2 = 'localhost,14534'

$syntaxErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref] $null, [ref] $syntaxErrors)
if ($syntaxErrors) {
    "FAIL  Move-FinanceApp.ps1: PowerShell cannot read it, line $($syntaxErrors[0].Extent.StartLineNumber): $($syntaxErrors[0].Message)"
    exit 1
}

$cred = try { Get-Secret -Name sql-lab -Vault PachaOps -WarningAction SilentlyContinue } catch { $null }
$app = try { Get-Secret -Name finance-report -Vault PachaOps -WarningAction SilentlyContinue } catch { $null }
if ($cred -isnot [pscredential] -or $app -isnot [pscredential]) {
    'FAIL  the secrets sql-lab and finance-report cannot be read in the vault PachaOps: run ./demos/module_12/00-setup.ps1.'
    exit 1
}
$text = Get-Content -Path $script -Raw
foreach ($secret in $cred, $app) {
    if ($text.Contains($secret.GetNetworkCredential().Password)) {
        $problems.Add("Move-FinanceApp.ps1 contains the password of $($secret.UserName): read it in the vault, with Get-Secret.")
    }
}

Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sourceLogin = Get-DbaLogin -SqlInstance $sql2 -SqlCredential $cred -Login finance_report -EnableException
if (-not (Get-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database Finance -EnableException) -or -not $sourceLogin) {
    'FAIL  the database Finance or the login finance_report is missing on sql2 (localhost,14534): run ./demos/module_12/00-setup.ps1.'
    exit 1
}
$count = 'SELECT COUNT_BIG(*) AS Rows FROM dbo.LedgerEntry;'
$expectedRows = (Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Database Finance -Query $count -EnableException).Rows
$expectedSid = [System.Convert]::ToHexString($sourceLogin.Sid)

# What a run of the script leaves: on sql1 the database and the login, on both instances the
# history of the copy backup (Copy-DbaDatabase names its files Finance_<timestamp>-1-of-3.bak).
$history = @'
DECLARE @sets TABLE (backup_set_id int PRIMARY KEY, media_set_id int);
INSERT INTO @sets (backup_set_id, media_set_id)
SELECT DISTINCT b.backup_set_id, b.media_set_id
FROM msdb.dbo.backupset AS b
JOIN msdb.dbo.backupmediafamily AS f ON f.media_set_id = b.media_set_id
WHERE b.database_name = N'Finance'
  AND f.physical_device_name LIKE N'/var/opt/mssql/backup/Finance[_]%-[0-9]-of-[0-9].bak';
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
function Get-CopyState {
    [pscustomobject]@{
        Database = [bool](Get-DbaDatabase -SqlInstance $sql1 -SqlCredential $cred -Database Finance -EnableException)
        Login    = Get-DbaLogin -SqlInstance $sql1 -SqlCredential $cred -Login finance_report -EnableException
    }
}
function Remove-Copy {
    $state = Get-CopyState
    if ($state.Database) {
        Remove-DbaDatabase -SqlInstance $sql1 -SqlCredential $cred -Database Finance -Confirm:$false -EnableException | Out-Null
    }
    if ($state.Login) {
        Remove-DbaLogin -SqlInstance $sql1 -SqlCredential $cred -Login finance_report -Confirm:$false -EnableException | Out-Null
    }
    foreach ($instance in $sql1, $sql2) {
        Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query $history -EnableException
    }
}

Remove-Copy
try {
    # 1. -WhatIf: nothing may be copied.
    $command = Get-Command -Name $script
    if (-not $command.Parameters.ContainsKey('WhatIf')) {
        $problems.Add('Move-FinanceApp.ps1 does not accept -WhatIf: keep SupportsShouldProcess in [CmdletBinding()].')
    }
    else {
        try {
            $null = & $script -WhatIf -WarningAction SilentlyContinue
        }
        catch {
            $problems.Add("Move-FinanceApp.ps1 -WhatIf stopped: $($_.Exception.Message)")
        }
        $state = Get-CopyState
        if ($state.Database -or $state.Login) {
            $problems.Add("Move-FinanceApp.ps1 -WhatIf copied $(@(if ($state.Database) { 'the database Finance' }; if ($state.Login) { 'the login finance_report' }) -join ' and ') to sql1: -WhatIf does not reach the dbatools commands by itself; ask `$PSCmdlet.ShouldProcess first.")
            Remove-Copy
        }
    }

    # 2. For real.
    $parameters = @{ WarningAction = 'SilentlyContinue' }
    if ($command.Parameters.ContainsKey('Confirm')) { $parameters.Confirm = $false }
    $rows = try {
        @(& $script @parameters)
    }
    catch {
        $problems.Add("Move-FinanceApp.ps1 stopped: $($_.Exception.Message)")
        @()
    }
    $state = Get-CopyState
    if (-not $state.Database) {
        $problems.Add('the database Finance is not on sql1 (localhost,14533).')
    }
    if (-not $state.Login) {
        $problems.Add('the login finance_report is not on sql1.')
    }
    elseif ([System.Convert]::ToHexString($state.Login.Sid) -ne $expectedSid) {
        $problems.Add("the login finance_report of sql1 has another SID than on sql2: its user in Finance is orphaned. Copy-DbaLogin keeps the SID; a login created by hand does not.")
    }
    if ($state.Database) {
        $orphans = @(Get-DbaDbOrphanUser -SqlInstance $sql1 -SqlCredential $cred -Database Finance -EnableException)
        if ($orphans.Count -gt 0) {
            $problems.Add("Finance on sql1 has $($orphans.Count) orphaned user(s): $($orphans.User -join ', ').")
        }
        $read = try {
            (Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $app -Database Finance -Query $count -EnableException).Rows
        }
        catch {
            $problems.Add("finance_report cannot read Finance on sql1 with the password of the vault: $($_.Exception.Message)")
            $null
        }
        if ($null -ne $read -and $read -ne $expectedRows) {
            $problems.Add("finance_report reads $read row(s) of dbo.LedgerEntry on sql1, expected $expectedRows, the rows of sql2.")
        }
    }
    if ($rows.Count -ne 1) {
        $problems.Add("Move-FinanceApp.ps1 returned $($rows.Count) object(s), expected one.")
    }
    else {
        $row = $rows[0]
        foreach ($property in 'Database', 'Login', 'DatabaseStatus', 'LoginStatus', 'SourceRows', 'Rows', 'Orphans', 'Verified') {
            if ($null -eq $row.PSObject.Properties[$property]) {
                $problems.Add("Move-FinanceApp.ps1: the property $property is missing.")
            }
        }
        if ($row.SourceRows -ne $expectedRows) {
            $problems.Add("Move-FinanceApp.ps1: SourceRows is '$($row.SourceRows)', expected $expectedRows.")
        }
        if ($row.Rows -ne $expectedRows) {
            $problems.Add("Move-FinanceApp.ps1: Rows is '$($row.Rows)', expected $expectedRows, read on sql1 as finance_report.")
        }
        if ($row.Orphans -ne 0) {
            $problems.Add("Move-FinanceApp.ps1: Orphans is '$($row.Orphans)', expected 0.")
        }
        if ($row.Verified -isnot [bool] -or -not $row.Verified) {
            $problems.Add("Move-FinanceApp.ps1: Verified is '$($row.Verified)', expected the boolean `$true.")
        }
    }
}
finally {
    try { Remove-Copy } catch { "WARN  the copy on sql1 could not be removed: $($_.Exception.Message)" }
}

# 3. The schedule: the trace of the last run of the nightly report.
if ($Solution) {
    $pwsh = [System.Environment]::ProcessPath
    Push-Location -Path ([System.Environment]::GetFolderPath('UserProfile'))
    & $pwsh -NoProfile -NonInteractive -File (Join-Path $root 'demos' 'module_12' '05-nightly-report.ps1') *> $null
    Pop-Location
}
if (-not (Test-Path -Path $trace)) {
    $problems.Add("no trace in lab/nightly-report.csv: schedule ./demos/module_12/05-nightly-report.ps1 on your computer (clip 12.3), and check again after its first run.")
}
else {
    $last = Import-Csv -Path $trace | Select-Object -Last 1
    $start = [datetime]::MinValue
    if (-not [datetime]::TryParseExact([string] $last.Start, 'yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture, 'None', [ref] $start)) {
        $problems.Add("the last line of lab/nightly-report.csv has no readable Start: '$($last.Start)'.")
    }
    elseif ($start -lt (Get-Date).AddHours(-26)) {
        $problems.Add("the last run in lab/nightly-report.csv started on $($last.Start), more than 26 hours ago: the scheduler has not run the report since.")
    }
    if ($last.ExitCode -ne '0') {
        $problems.Add("the last run in lab/nightly-report.csv ended with exit code $($last.ExitCode), with PowerShell $($last.PowerShell) ($($last.Pwsh)): $($last.Message)")
    }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object -Process { "FAIL  $_" }
    exit 1
}
"OK    module 12: Finance and finance_report work on sql1, and the nightly report ran on $($last.Start) with exit code 0."
exit 0
