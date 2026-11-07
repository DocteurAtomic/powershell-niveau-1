# Module 6, clip 6.4: the retention asked by the team, on the whole backup share. Typed one
# command at a time at the console, from the root of the clone, with the backup files created
# for 2 November 2026; for your own files, leave out -ReferenceDate, which is now by default.
# The last command creates the backup files again, for the next modules.

. ./demos/module_06/backup-functions.ps1
Remove-OldBackup -Path lab/backups -RetentionDays 28 -ReferenceDate 2026-11-02 -WhatIf
$removed = Remove-OldBackup -Path lab/backups -RetentionDays 28 -ReferenceDate 2026-11-02
$removed.Count
$removed | Group-Object -Property { $_.Directory.Name } -NoElement
(Get-ChildItem -Path lab/backups -Recurse -File).Count
Test-Path -Path lab/backups/sql1/Finance/FULL/README-restore.txt
Get-ChildItem -Path lab/backups -Recurse -File |
    Sort-Object -Property LastWriteTime |
    Select-Object -First 3 -Property Name, LastWriteTime
./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02
