# ci: skip. Two commands stop on purpose: typed at the console, each one stops alone.

# Module 7, clip 7.1: errors that continue and errors that stop.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# The morning report of module 5 on a folder that is gone: an error, and an empty file.
./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql9 | Export-Csv -Path lab/backup-report.csv
Get-Item -Path lab/backup-report.csv | Select-Object -Property Name, Length
Remove-Item -Path lab/backup-report.csv

# Three folders, one of them missing: the error does not stop the command.
$Error.Clear()
Get-Item -Path lab/backups/sql1/DBA, lab/backups/sql1/Payroll, lab/backups/sql1/Finance
$Error.Count

# The error is an object, an ErrorRecord.
$Error[0] | Select-Object -Property *
$Error[0].Exception.GetType().FullName

# -ErrorAction changes what one command does with its errors.
Get-Item -Path lab/backups/sql1/DBA, lab/backups/sql1/Payroll, lab/backups/sql1/Finance -ErrorAction Stop
$Error.Clear()
Get-Item -Path lab/backups/sql1/DBA, lab/backups/sql1/Payroll, lab/backups/sql1/Finance -ErrorAction SilentlyContinue
$Error.Count
Get-Item -Path lab/backups/sql1/Payroll -ErrorAction Ignore
$Error.Count

# $ErrorActionPreference does it for every command, the scripts you run included. The
# report stops, but Export-Csv has already created its file.
$ErrorActionPreference
$ErrorActionPreference = 'Stop'
./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql9 | Export-Csv -Path lab/backup-report.csv
Get-Item -Path lab/backup-report.csv | Select-Object -Property Name, Length
Remove-Item -Path lab/backup-report.csv
$ErrorActionPreference = 'Continue'
