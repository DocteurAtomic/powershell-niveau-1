# Solution of the exercise of module 3, part 1.
Get-ChildItem -Path lab/backups/sql1 -Recurse -File -Filter sql1_* |
    Group-Object -Property { ($_.Name -split '_')[1] } |
    Select-Object -Property @{ Name = 'Database'; Expression = { $_.Name } },
        @{ Name = 'FileCount'; Expression = { $_.Count } },
        @{ Name = 'SizeMB'; Expression = { [math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1MB, 1) } },
        @{ Name = 'LastBackup'; Expression = { ($_.Group | Measure-Object -Property LastWriteTime -Maximum).Maximum } }
