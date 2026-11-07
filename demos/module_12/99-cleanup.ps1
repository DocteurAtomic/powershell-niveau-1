<#
ci: skip (it asks for a confirmation; the lab of the continuous integration is thrown away)
.SYNOPSIS
Removes what the demos and the exercise of module 12 left on the lab.

.DESCRIPTION
On both instances: the database Planning, the logins planning_app and finance_report, the
job "Planning - nightly purge" and the jobs whose name starts with m12_, and the history
of the backups that Copy-DbaDatabase took to copy Planning or Finance (copy-only backups in
three files, named <database>_<timestamp>-1-of-3.bak, which it deletes itself), with the
restores that read them. On sql1, the copy of Finance made by the exercise. On sql2, the
user finance_report of Finance. In the vault, the secrets planning-app and finance-report.

Leaves alone the database Finance of sql2 and its backup of module 10: module 10's
99-cleanup.ps1 removes them. Run ./demos/module_12/00-setup.ps1 to start module 12 again.
Shown first with -WhatIf, like every command of the course that removes something.

.EXAMPLE
./demos/module_12/99-cleanup.ps1 -WhatIf

.EXAMPLE
./demos/module_12/99-cleanup.ps1 -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()
$ErrorActionPreference = 'Stop'
$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sql1 = 'localhost,14533'
$sql2 = 'localhost,14534'

# The history of the copy backups of Planning and Finance, and of the restores that read them.
$history = @'
DECLARE @sets TABLE (backup_set_id int PRIMARY KEY, media_set_id int);
INSERT INTO @sets (backup_set_id, media_set_id)
SELECT DISTINCT b.backup_set_id, b.media_set_id
FROM msdb.dbo.backupset AS b
JOIN msdb.dbo.backupmediafamily AS f ON f.media_set_id = b.media_set_id
WHERE b.database_name IN (N'Planning', N'Finance')
  AND f.physical_device_name LIKE N'/var/opt/mssql/backup/%[_]%-[0-9]-of-[0-9].bak';
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
SELECT COUNT(*) AS Backups FROM @sets;
'@
# Copy files that a stopped copy may have left in the shared folder.
$files = @'
SELECT full_filesystem_path AS FullName
FROM sys.dm_os_enumerate_filesystem(N'/var/opt/mssql/backup', N'*-of-*.bak')
WHERE is_directory = 0 AND (file_or_directory_name LIKE N'Planning[_]%' OR file_or_directory_name LIKE N'Finance[_]%');
'@

foreach ($instance in $sql1, $sql2) {
    $databases = @(if ($instance -eq $sql1) { 'Planning', 'Finance' } else { 'Planning' }) |
        Where-Object -FilterScript { Get-DbaDatabase -SqlInstance $instance -SqlCredential $cred -Database $_ -EnableException }
    $logins = @(Get-DbaLogin -SqlInstance $instance -SqlCredential $cred -Login planning_app, finance_report -EnableException | Select-Object -ExpandProperty Name)
    $jobs = @(Get-DbaAgentJob -SqlInstance $instance -SqlCredential $cred -EnableException |
        Where-Object -FilterScript { $_.Name -eq 'Planning - nightly purge' -or $_.Name -like 'm12_*' } | Select-Object -ExpandProperty Name)
    $target = "$instance, database(s) $($databases -join ', '), login(s) $($logins -join ', '), job(s) $($jobs -join ', ') and the history of the copies"
    if ($PSCmdlet.ShouldProcess($target, 'Remove')) {
        foreach ($job in $jobs) {
            Remove-DbaAgentJob -SqlInstance $instance -SqlCredential $cred -Job $job -Confirm:$false -EnableException | Out-Null
        }
        foreach ($database in $databases) {
            Remove-DbaDatabase -SqlInstance $instance -SqlCredential $cred -Database $database -Confirm:$false -EnableException | Out-Null
        }
        if ($instance -eq $sql2 -and (Get-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database Finance -EnableException)) {
            Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Database Finance -Query 'DROP USER IF EXISTS finance_report;' -EnableException
        }
        foreach ($login in $logins) {
            Remove-DbaLogin -SqlInstance $instance -SqlCredential $cred -Login $login -Confirm:$false -EnableException | Out-Null
        }
        $count = (Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query $history -EnableException).Backups
        foreach ($path in @(Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query $files -EnableException | Select-Object -ExpandProperty FullName)) {
            Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query 'EXEC master.sys.xp_delete_files @path;' -SqlParameter @{ path = $path } -EnableException
        }
        "ok    $instance`: $($databases.Count) database(s), $($logins.Count) login(s), $($jobs.Count) job(s), the history of $count backup(s) removed"
    }
}
if ($PSCmdlet.ShouldProcess('the vault PachaOps, secrets planning-app and finance-report', 'Remove')) {
    foreach ($name in 'planning-app', 'finance-report') {
        if (Get-SecretInfo -Name $name -Vault PachaOps) { Remove-Secret -Name $name -Vault PachaOps }
    }
    'ok    the secrets planning-app and finance-report are removed from the vault'
}
