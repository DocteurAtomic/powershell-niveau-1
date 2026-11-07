# Module 4, clip 4.3: the inventory read from a CSV file, and the weekly CSV for accounting.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# Import-Csv returns one object per line; every property is a string.
$instances = Import-Csv -Path data/instances.csv
$instances | Select-Object -Property Name, SqlInstance, Environment, Owner
$instances | Get-Member -MemberType NoteProperty
$instances | Where-Object -Property Environment -eq -Value Production | Select-Object -Property Name, Owner

# The backup storage per database over the last seven days, for accounting.
$limit = (Get-Date -Date '2026-11-02').AddDays(-7)
$storage = Get-ChildItem -Path lab/backups/sql1 -Recurse -File -Filter sql1_* |
    Where-Object -Property LastWriteTime -ge -Value $limit |
    Group-Object -Property { $_.Directory.Parent.Name } |
    Select-Object -Property @{ Name = 'Database'; Expression = { $_.Name } },
        @{ Name = 'Files'; Expression = { $_.Count } },
        @{ Name = 'SizeMB'; Expression = { [math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1MB, 1) } }
$storage
$storage | Export-Csv -Path lab/backup-storage.csv
Get-Content -Path lab/backup-storage.csv
# A French spreadsheet expects a semicolon.
$storage | Export-Csv -Path lab/backup-storage.csv -Delimiter ';'
Get-Content -Path lab/backup-storage.csv
# Values are written with the culture of the session.
[cultureinfo]::CurrentCulture = 'fr-FR'
$storage | ConvertTo-Csv -Delimiter ';'
[cultureinfo]::CurrentCulture = 'en-US'

# Read back, the sizes are strings, and they sort as strings.
$imported = Import-Csv -Path lab/backup-storage.csv -Delimiter ';'
$imported | Sort-Object -Property SizeMB -Descending
$imported | Sort-Object -Property { [double]$_.SizeMB } -Descending
Remove-Item -Path lab/backup-storage.csv
