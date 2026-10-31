# Module 2, clip 2.4: format last.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# A table and a list, with the properties you choose.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Format-Table -Property Name, Length, LastWriteTime
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Select-Object -First 1 | Format-List -Property Name, Length, LastWriteTime, FullName

# The table shows three decimals; the value has two.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak |
    Select-Object -First 1 -Property Name, @{ Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) } } |
    Format-List

# What a Format-* command sends down the pipeline: formatting objects, not files.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Format-Table -Property Name, Length | Get-Member | Select-Object -Property TypeName -Unique
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Format-Table -Property Name, Length | Sort-Object -Property Length
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Format-Table -Property Name, Length | Export-Csv -Path lab/finance.csv
Get-Content -Path lab/finance.csv

# The same export with Select-Object: real properties, real values.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Select-Object -Property Name, Length | Export-Csv -Path lab/finance.csv
Get-Content -Path lab/finance.csv

# A script that outputs two kinds of objects: run it, then type its two commands one by one.
Get-Content -Path demos/module_02/05-mixed-output.ps1
./demos/module_02/05-mixed-output.ps1
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Select-Object -Property Name, Length
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Measure-Object -Property Length -Sum

# Out-GridView exists only on Windows.
Get-Command -Name Out-GridView

# The answer to the team, run again.
Get-ChildItem -Path lab/backups -Recurse -File |
    Where-Object -Property LastWriteTime -lt -Value (Get-Date -Date '2026-11-02').AddDays(-7) |
    Sort-Object -Property Length -Descending |
    Select-Object -Property Name, @{ Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) } }

Remove-Item -Path lab/finance.csv
