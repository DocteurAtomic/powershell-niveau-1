# Module 2, clip 2.2: filter and sort.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# The empty backup: a file whose Length is 0.
Get-ChildItem -Path lab/backups -Recurse -File | Where-Object -Property Length -eq -Value 0

# The trap: > is not "greater than", it redirects the output to a file named 0.
Get-ChildItem -Path lab/backups -Recurse -File | Where-Object -Property Length > 0
Get-ChildItem -Path . -File
Remove-Item -Path ./0 -WhatIf
Remove-Item -Path ./0

# A wildcard with -like: the text file left among the backups.
Get-ChildItem -Path lab/backups -Recurse -File | Where-Object -Property Name -like -Value '*.txt'

# The date seven days before the reference date of the demo files.
# On your own files, created for today, write (Get-Date).AddDays(-7).
Get-Date -Date '2026-11-02'
(Get-Date -Date '2026-11-02').AddDays(-7)

# Older than seven days, biggest first, the first five.
Get-ChildItem -Path lab/backups -Recurse -File |
    Where-Object -Property LastWriteTime -lt -Value (Get-Date -Date '2026-11-02').AddDays(-7) |
    Sort-Object -Property Length -Descending |
    Select-Object -First 5

# Two conditions need a script block, and $_ is the object being tested.
Get-ChildItem -Path lab/backups -Recurse -File |
    Where-Object -FilterScript { $_.Length -eq 0 -or $_.Extension -eq '.txt' }

# Filter left: the file system filters before PowerShell builds the objects.
# Take a large folder of your machine (on Windows, C:\Windows\System32 for instance).
Measure-Command { Get-ChildItem -Path /usr/share/icons -Recurse | Where-Object -Property Extension -eq -Value '.png' }
Measure-Command { Get-ChildItem -Path /usr/share/icons -Recurse -Filter *.png }
