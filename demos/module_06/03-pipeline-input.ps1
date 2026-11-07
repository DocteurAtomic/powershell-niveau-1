# Module 6, clip 6.3: pipeline input. Typed one command at a time at the console, from the root
# of the clone, with the backup files created for 2 November 2026.

# Without a process block, the body runs once, at the end: only the last object is left.
function Show-Input {
    param([Parameter(ValueFromPipeline)] $InputObject)
    "received: $InputObject"
}
1, 2, 3 | Show-Input

# begin runs once, process once per object, end once.
function Show-Input {
    param([Parameter(ValueFromPipeline)] $InputObject)
    begin { 'begin' }
    process { "received: $InputObject" }
    end { 'end' }
}
1, 2, 3 | Show-Input
Show-Input -InputObject 1, 2, 3

# By value and by property name.
. ./demos/module_06/backup-functions.ps1
'sql1', 'sql2' | Get-BackupSummary
Get-BackupSummary -Name sql1, sql2
Import-Csv -Path data/instances.csv | Get-BackupSummary -Verbose
Get-Help -Name Get-BackupSummary -Parameter Name
Import-Csv -Path data/instances.csv | Get-BackupSummary | Where-Object -Property FileCount -EQ -Value 0
