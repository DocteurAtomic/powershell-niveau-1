<#
ci: skip (it asks for a confirmation; the lab of the continuous integration is thrown away)
.SYNOPSIS
Removes what the demos and the exercise of module 11 left on the lab.

.DESCRIPTION
Drops every database whose name starts with m11_ on both instances, deletes the files whose
name starts with m11_ in the shared backup folder (/var/opt/mssql/backup) and in the data
folder of each instance (/var/opt/mssql/data), and deletes from msdb the history of the
backups written to those files, on both instances: a restore records in msdb the backup it
read, so the instance that restored a copy has that history too.

Leaves alone the database Finance and its backup of module 10, and everything else: module
12 uses them. Shown first with -WhatIf, like every command of the course that removes
something.

.EXAMPLE
./demos/module_11/99-cleanup.ps1 -WhatIf

.EXAMPLE
./demos/module_11/99-cleanup.ps1 -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()
$ErrorActionPreference = 'Stop'
$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

# The history of the backups written to an m11_ file, as msdb.dbo.sp_delete_database_backuphistory
# deletes the history of a whole database, then the files themselves.
$history = @'
DECLARE @sets TABLE (backup_set_id int PRIMARY KEY, media_set_id int);
INSERT INTO @sets (backup_set_id, media_set_id)
SELECT DISTINCT b.backup_set_id, b.media_set_id
FROM msdb.dbo.backupset AS b
JOIN msdb.dbo.backupmediafamily AS f ON f.media_set_id = b.media_set_id
WHERE f.physical_device_name LIKE N'/var/opt/mssql/%/m11[_]%';
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
# The data folder of each instance, and the shared backup folder, seen from the first one.
$dataFiles = @'
SELECT full_filesystem_path AS FullName
FROM sys.dm_os_enumerate_filesystem(N'/var/opt/mssql/data', N'm11_*') WHERE is_directory = 0;
'@
$allFiles = @'
SELECT full_filesystem_path AS FullName
FROM sys.dm_os_enumerate_filesystem(N'/var/opt/mssql/data', N'm11_*') WHERE is_directory = 0
UNION ALL
SELECT full_filesystem_path
FROM sys.dm_os_enumerate_filesystem(N'/var/opt/mssql/backup', N'm11_*') WHERE is_directory = 0;
'@

$lab = 'localhost,14533', 'localhost,14534'
foreach ($instance in $lab) {
    $files = if ($instance -eq $lab[0]) { $allFiles } else { $dataFiles }
    $databases = @(Get-DbaDatabase -SqlInstance $instance -SqlCredential $cred -EnableException |
        Where-Object -Property Name -Like -Value 'm11_*')
    $paths = @(Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query $files -EnableException | Select-Object -ExpandProperty FullName)
    $target = "$instance, $($databases.Count) m11_ database(s), $($paths.Count) m11_ file(s) and their backup history"
    if ($PSCmdlet.ShouldProcess($target, 'Remove')) {
        foreach ($database in $databases) {
            Remove-DbaDatabase -SqlInstance $instance -SqlCredential $cred -Database $database.Name -Confirm:$false -EnableException | Out-Null
        }
        $count = (Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query $history -EnableException).Backups
        # The data files of a dropped copy are gone with it: list the files again.
        foreach ($path in @(Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query $files -EnableException | Select-Object -ExpandProperty FullName)) {
            Invoke-DbaQuery -SqlInstance $instance -SqlCredential $cred -Query 'EXEC master.sys.xp_delete_files @path;' -SqlParameter @{ path = $path } -EnableException
        }
        "ok    $instance`: $($databases.Count) database(s), $($paths.Count) file(s), the history of $count backup(s) removed"
    }
}
