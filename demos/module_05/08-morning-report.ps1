# Module 5, clip 5.5: the morning report, run twice with different parameters, then exported.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026, and a report written at 8 AM that day; for your
# own files, leave out -ReferenceDate, which is now by default.
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

Get-Help -Name ./demos/module_05/06-backup-report.ps1 -Parameter MaxAgeHours
./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql1 -ReferenceDate '2026-11-02 08:00' | Format-Table
./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql1 -MaxAgeHours 168 -ReferenceDate '2026-11-02 08:00' | Format-Table
$report = ./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql1 -IssuesOnly -ReferenceDate '2026-11-02 08:00'
$report | Get-Member -MemberType NoteProperty
$report | Sort-Object -Property AgeHours -Descending | Select-Object -Property Database, AgeHours, Status

# Write-Host writes on the screen, in the information stream, not in the output.
$text = ./demos/module_05/07-host-report.ps1
$null -eq $text
./demos/module_05/07-host-report.ps1 6> $null

# The answer to the team: the issues of the morning, in a CSV file.
./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql1 -IssuesOnly -ReferenceDate '2026-11-02 08:00' |
    Export-Csv -Path lab/backup-report.csv
Get-Content -Path lab/backup-report.csv
Remove-Item -Path lab/backup-report.csv
