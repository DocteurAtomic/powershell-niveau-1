# Module 6, clip 6.2: advanced functions. Typed one command at a time at the console, from the
# root of the clone, with the backup files created for 2 November 2026.

. ./demos/module_06/backup-functions.ps1
Get-Command -Name Get-OldBackup -Syntax
(Get-OldBackup -Path lab/backups -RetentionDays 28 -ReferenceDate 2026-11-02).Count

# -Verbose shows the messages of Write-Verbose.
Get-OldBackup -Path lab/backups/sql1 -RetentionDays 2 -Type LOG -ReferenceDate 2026-11-02 -Verbose |
    Select-Object -Property Name, LastWriteTime

# Validation: the values are checked before the function runs.
Get-OldBackup -Path lab/backups -RetentionDays 28 -Type COPY
Get-OldBackup -Path lab/backups -RetentionDays 0
Get-OldBackup -Path lab/backups -Days 28

# The common parameters, added by [CmdletBinding()].
(Get-Command -Name Get-OldBackup).Parameters.Keys

# The comment-based help.
Get-Help -Name Get-OldBackup
Get-Help -Name Get-OldBackup -Parameter RetentionDays
