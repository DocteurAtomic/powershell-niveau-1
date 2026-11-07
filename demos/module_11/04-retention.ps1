# Module 11, clip 11.4: the retention, on the backup share of the team (lab/backups).
# Run from the root of the clone, one command at a time at the console, with the backup files
# created for 2 November 2026 (./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02). The
# counts of the dbatools commands depend on the day you run them: they count from now. The
# last commands create the files again, then run the answer of the module.

# The function of module 6 counts from a reference date, now by default.
. ./demos/module_06/backup-functions.ps1
(Get-OldBackup -Path lab/backups -RetentionDays 28 -ReferenceDate 2026-11-02).Count
(Get-OldBackup -Path lab/backups -RetentionDays 28).Count

# dbatools: Find-DbaBackup finds the files, Remove-DbaBackup removes them; both count from now.
$old = Find-DbaBackup -Path lab/backups -BackupFileExtension bak -RetentionPeriod 28d
$old.Count
$old | Group-Object -Property { $_.Directory.Name } -NoElement
(Find-DbaBackup -Path lab/backups -BackupFileExtension trn -RetentionPeriod 28d).Count
(Find-DbaBackup -Path lab/backups -BackupFileExtension bak -RetentionPeriod 28d -CheckArchiveBit).Count
(Get-Item -Path lab/backups/sql1/Finance/FULL/*.bak | Select-Object -First 1).Attributes
Remove-DbaBackup -Path lab/backups -BackupFileExtension bak -RetentionPeriod 28d -WhatIf

# The removal, with the reference date of the demos, and what the age rule forgets: a
# differential backup is useless without the full backup it starts from.
$removed = Remove-OldBackup -Path lab/backups -RetentionDays 28 -ReferenceDate 2026-11-02
$removed.Count
Get-ChildItem -Path lab/backups -Recurse -File -Include *.bak |
    Group-Object -Property { $_.Directory.Parent.Name } |
    ForEach-Object -Process {
        $full = $_.Group | Where-Object -FilterScript { $_.Directory.Name -eq 'FULL' } | Sort-Object -Property LastWriteTime | Select-Object -First 1
        $orphans = $_.Group | Where-Object -FilterScript { $_.Directory.Name -eq 'DIFF' -and $_.LastWriteTime -lt $full.LastWriteTime }
        [pscustomobject]@{ Database = $_.Name; OldestFull = $full.LastWriteTime; OrphanDiff = @($orphans).Count }
    }

# The files again, for the next modules, and the answer of the module, run again.
./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02
./demos/module_11/05-verified-backups.ps1 | Format-Table -Property Instance, Database, TestedOn, CompressedMB, Restore, Dbcc, Verified
