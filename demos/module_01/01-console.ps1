# Module 1, clip 1.1: the console, the lab and the request of the team.
# Run from the root of the clone, one command at a time at the console (or select a line
# and press F8 in VS Code).
# The video uses backup files created for 2 November 2026; without -ReferenceDate, the
# script creates them for today.

# The version of PowerShell: 7.6, edition Core.
$PSVersionTable
$PSVersionTable.PSVersion

# The first script of the course: the fake backup files of the team share (read in module 5).
./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# The backup share, one level after the other.
Get-ChildItem -Path lab/backups
Get-ChildItem -Path lab/backups/sql1
Get-ChildItem -Path lab/backups/sql1/PachadataTraining
