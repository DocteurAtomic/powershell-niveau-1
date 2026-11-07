# Module 4, clip 4.1: paths, then text files written, copied and removed.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# A path is built by Join-Path, which checks nothing; Test-Path checks.
$draft = Join-Path -Path lab -ChildPath draft
$draft
Join-Path -Path lab -ChildPath backups -AdditionalChildPath sql1, Finance
Test-Path -Path $draft
Test-Path -Path lab/backups/sql1/Finance
# On Linux, the case of a name matters; both separators work in PowerShell commands.
Test-Path -Path lab/Backups/sql1/Finance
Test-Path -Path 'lab\backups\sql1\Finance'
[System.IO.Path]::DirectorySeparatorChar
Resolve-Path -Path lab/backups/sql1/Finance
Resolve-Path -Path lab/backups/sql2

# A draft folder for what goes to accounting, and a text file in it.
New-Item -ItemType Directory -Path $draft
$readme = Join-Path -Path $draft -ChildPath README.txt
Set-Content -Path $readme -Value 'Stockage des sauvegardes, arrêté au 2026-11-02.'
Add-Content -Path $readme -Value 'Une ligne par base, taille en Mo.'
Get-Content -Path $readme
# UTF-8 without a byte order mark: the ê takes two bytes, C3 AA.
Format-Hex -Path $readme

# Set-Content writes each object as a string; Out-File and > write what the screen shows.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Set-Content -Path lab/draft/files.txt
Get-Content -Path lab/draft/files.txt
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak > lab/draft/listing.txt
Get-Content -Path lab/draft/listing.txt

# Copy, then remove: a copy that would replace a file, and a removal, are shown with -WhatIf first.
$previous = Join-Path -Path $draft -ChildPath README.previous.txt
Copy-Item -Path $readme -Destination $previous
Copy-Item -Path $readme -Destination $previous -WhatIf
Get-ChildItem -Path $draft
Remove-Item -Path $draft -Recurse -WhatIf
Remove-Item -Path $draft -Recurse
Test-Path -Path $draft
