# Module 7, clip 7.4: the streams, the transcript, and the morning report that stops.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026, and a report written at 8 AM that day; for your
# own files, leave out -ReferenceDate, which is now by default.
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# Each Write- cmdlet writes in its own stream; only the output goes into the variable.
$result = ./demos/module_07/05-streams.ps1
$result
./demos/module_07/05-streams.ps1 -Verbose -InformationAction Continue 2> $null 3> $null
./demos/module_07/05-streams.ps1 *> lab/streams.txt
Get-Content -Path lab/streams.txt
Remove-Item -Path lab/streams.txt

# The morning report, with -Verbose, kept in a transcript. The command stays on one line:
# the transcript records a command typed on several lines badly.
Start-Transcript -Path lab/morning-report.log
./demos/module_07/06-backup-report.ps1 -Path lab/backups/sql1 -IssuesOnly -ReferenceDate '2026-11-02 08:00' -Verbose | Format-Table
Stop-Transcript
Get-Content -Path lab/morning-report.log
Remove-Item -Path lab/morning-report.log

# Export only what the report returned: when it stops, no file is written.
try {
    $report = ./demos/module_07/06-backup-report.ps1 -Path lab/backups/sql9 -IssuesOnly
    $report | Export-Csv -Path lab/backup-report.csv
} catch {
    "No report: $($_.Exception.Message)"
}
Test-Path -Path lab/backup-report.csv

# The answer to the team: on a missing folder, the report stops, says why, and exits with 1.
pwsh -NoProfile -File ./demos/module_07/06-backup-report.ps1 -Path lab/backups/sql9
$LASTEXITCODE
if ($LASTEXITCODE -ne 1) { throw "The report should exit with 1 on a missing folder, not $LASTEXITCODE." }
