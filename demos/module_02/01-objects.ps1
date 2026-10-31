# Module 2, clip 2.1: objects, not text.
# Run from the root of the clone, one command at a time at the console (or select a line
# and press F8 in VS Code). Run as a whole script, all the output goes to a single
# formatter, which is what clip 2.4 shows.
# The video uses backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# The PowerShell view of a folder.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL

# The same folder seen by the ls program of Linux or macOS: lines of text.
ls -l lab/backups/sql1/Finance/FULL
ls -l lab/backups/sql1/Finance/FULL | Get-Member -MemberType Property

# What Get-ChildItem sends down the pipeline: System.IO.FileInfo objects.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL | Get-Member
Get-ChildItem -Path lab/backups/sql1/Finance/FULL | Get-Member -MemberType Property

# Size is added by PowerShell on Linux and macOS; Length exists everywhere.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL | Get-Member -Name Length, Size

# A folder and its files: one section per type.
Get-ChildItem -Path lab/backups/sql1/Finance -Recurse | Get-Member -MemberType Property

# Every property of one file, not only the six columns of the view.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Select-Object -First 1 -Property *
