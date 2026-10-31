# Module 2, clip 2.3: calculate and group.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# Select-Object builds new objects that keep only the chosen properties.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Select-Object -Property Name, Length, LastWriteTime
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Select-Object -Property Name, Length | Get-Member

# The numeric suffixes.
1KB
1MB

# A calculated property: a name and an expression, in a hash table.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak |
    Select-Object -Property Name, @{ Name = 'SizeMB'; Expression = { $_.Length / 1MB } }
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak |
    Select-Object -Property Name, @{ Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) } }

# Totals: one GenericMeasureInfo object.
Get-ChildItem -Path lab/backups -Recurse -File | Measure-Object -Property Length -Sum -Average -Maximum

# Groups: one GroupInfo object per value, here per backup type (the folder name).
Get-ChildItem -Path lab/backups -Recurse -File | Group-Object -Property { $_.Directory.Name }
Get-ChildItem -Path lab/backups -Recurse -File | Group-Object -Property { $_.Directory.Name } | Get-Member -MemberType Property
Get-ChildItem -Path lab/backups -Recurse -File |
    Group-Object -Property { $_.Directory.Name } |
    Select-Object -Property Name, Count, @{ Name = 'SizeMB'; Expression = { [math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1MB, 1) } }

# The answer to the team: backup files older than seven days, biggest first, size in MB.
Get-ChildItem -Path lab/backups -Recurse -File |
    Where-Object -Property LastWriteTime -lt -Value (Get-Date -Date '2026-11-02').AddDays(-7) |
    Sort-Object -Property Length -Descending |
    Select-Object -Property Name, @{ Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) } }
