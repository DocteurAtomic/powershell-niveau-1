# Module 3, clip 3.4: a hash table or an object, then the instance cards.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# Two cards written as hash tables: keys and values, not properties.
$tables = [ordered]@{ Name = 'sql1'; Port = 14533; Owner = 'planning' },
    [ordered]@{ Name = 'sql2'; Port = 14534; Owner = 'planning' }
$tables
$tables | Select-Object -Property Name, Port
$tables[0] | Get-Member -MemberType Properties

# The same cards as objects: [pscustomobject] turns the keys into properties.
$objects = [pscustomobject]@{ Name = 'sql1'; Port = 14533; Owner = 'planning' },
    [pscustomobject]@{ Name = 'sql2'; Port = 14534; Owner = 'planning' }
$objects
$objects | Get-Member -MemberType Properties

# The cards of the two lab instances, built by 05-instance-cards.ps1, which returns only cards.
$cards = ./demos/module_03/05-instance-cards.ps1
$cards
$cards | Get-Member -MemberType Properties
$cards | Sort-Object -Property FullBackupAgeHours | Select-Object -Property Name, LastFullBackup, FullBackupAgeHours
$cards | Where-Object -FilterScript { $null -eq $_.LastFullBackup }

# Export-Csv and Get-Content are the subject of module 4; lab/ is ignored by Git.
$cards | Export-Csv -Path lab/instance-cards.csv
Get-Content -Path lab/instance-cards.csv
Remove-Item -Path lab/instance-cards.csv

# The answer to the team, run again: one card per instance, in a table.
./demos/module_03/05-instance-cards.ps1 | Format-Table -Property Name, SqlInstance, Port, Owner, DatabaseCount, LastFullBackup
