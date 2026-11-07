# Module 4, clip 4.4: the weekly report, the answer to accounting and to the team.
# Unlike the other scripts of this folder, this one runs as a whole, from the root of the
# clone:
#   ./demos/module_04/05-weekly-report.ps1
# It reads its settings from weekly-report.json, writes the backup storage per database to a
# CSV file for accounting, and returns only the failed logins per account.
# The video uses backup files created for 2 November 2026. For your own files, write
# (Get-Date) instead.
$referenceDate = Get-Date -Date '2026-11-02'
$config = Get-Content -Path demos/module_04/weekly-report.json -Raw | ConvertFrom-Json

# The CSV file for accounting, one line per database, named after the day.
$null = New-Item -ItemType Directory -Path $config.Export.Folder -Force
$csv = Join-Path -Path $config.Export.Folder -ChildPath ('backup-storage-{0:yyyy-MM-dd}.csv' -f $referenceDate)
Get-ChildItem -Path $config.BackupPath -Recurse -File -Filter sql1_* |
    Where-Object -Property LastWriteTime -ge -Value $referenceDate.AddDays(-$config.Days) |
    Group-Object -Property { $_.Directory.Parent.Name } |
    Select-Object -Property @{ Name = 'Database'; Expression = { $_.Name } },
        @{ Name = 'Files'; Expression = { $_.Count } },
        @{ Name = 'SizeMB'; Expression = { [math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1MB, 1) } } |
    Export-Csv -Path $csv -Delimiter $config.Export.Delimiter

# The failed logins per account, the only output of the script.
Select-String -Path (Join-Path -Path $config.ErrorlogPath -ChildPath '*') -Pattern 'Login failed for user ''(\w+)''' |
    Group-Object -Property { $_.Matches[0].Groups[1].Value } -NoElement |
    Sort-Object -Property Count -Descending |
    Select-Object -Property @{ Name = 'Account'; Expression = { $_.Name } },
        @{ Name = 'Failures'; Expression = { $_.Count } }
