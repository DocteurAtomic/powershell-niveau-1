# Module 6, clip 6.1: from a command to a function. Typed one command at a time at the
# console, from the root of the clone, with the backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# The pipeline of module 2: the backup files older than 28 days.
$limit = (Get-Date -Date '2026-11-02').AddDays(-28)
$old = Get-ChildItem -Path lab/backups -Recurse -File -Include *.bak, *.trn |
    Where-Object -Property LastWriteTime -LT -Value $limit
$old.Count

# The same pipeline, named, with parameters.
function Get-OldBackup {
    param(
        [string] $Path,
        [int] $RetentionDays,
        [datetime] $ReferenceDate = (Get-Date)
    )
    $limit = $ReferenceDate.AddDays(-$RetentionDays)
    Get-ChildItem -Path $Path -Recurse -File -Include *.bak, *.trn |
        Where-Object -Property LastWriteTime -LT -Value $limit
}
(Get-OldBackup -Path lab/backups -RetentionDays 28 -ReferenceDate 2026-11-02).Count
Get-OldBackup -Path lab/backups/sql1/Finance -RetentionDays 28 -ReferenceDate 2026-11-02 |
    Select-Object -Property Name, LastWriteTime
Get-Command -Name Get-OldBackup

# Scope: an assignment in a function creates a local variable.
$total = 0
function Add-Total {
    param([int] $Count)
    $total = $total + $Count
    "inside: $total"
}
Add-Total -Count 5
$total
# $script: writes the variable of the script; at the console, the script scope is the global scope.
function Add-Total {
    param([int] $Count)
    $script:total = $script:total + $Count
}
Add-Total -Count 5
Add-Total -Count 3
$total

# Everything that is not captured goes to the output, return or not.
function Get-BackupCount {
    param([string] $Path)
    "Counting the backup files of $Path"
    $files = Get-ChildItem -Path $Path -Recurse -File -Include *.bak, *.trn
    return $files.Count
}
$count = Get-BackupCount -Path lab/backups/sql1/Finance
$count
$count.GetType().FullName

# A function in a file: run, then dot-sourced.
Remove-Item -Path Function:Get-OldBackup
./demos/module_06/old-backups.ps1
Get-Command -Name Get-OldBackup
. ./demos/module_06/old-backups.ps1
Get-Command -Name Get-OldBackup
