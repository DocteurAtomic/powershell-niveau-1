# Module 3, clip 3.3: arrays and hash tables.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# An array: @( ), an index from 0, -1 for the last item.
$types = @('FULL', 'DIFF', 'LOG')
$types[0]
$types[-1]
$types.Count
$types += 'COPY'
$types

# += copies the array at each addition: nothing to see on four items, seconds on 40,000.
# (foreach is a loop, the subject of module 5.)
(Measure-Command -Expression { $numbers = @(); foreach ($i in 1..40000) { $numbers += $i } }).TotalMilliseconds
(Measure-Command -Expression { $numbers = foreach ($i in 1..40000) { $i } }).TotalMilliseconds

# Member-access enumeration: a property of the items, read on the array.
$files = Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak
$files.Name
$files.Length
$files.Count
($files | Measure-Object -Property Length -Sum).Sum
$one = Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *20261101*
$one.Length
@($one).Length

# The comma builds an array, also in the arguments of a command: quote an instance name.
Write-Output -InputObject localhost,14533
Write-Output -InputObject localhost,14533 | Get-Member | Select-Object -Property TypeName -Unique
Write-Output -InputObject 'localhost,14533' | Get-Member | Select-Object -Property TypeName -Unique

# A hash table: keys and values.
$ports = @{ sql1 = 14533; sql2 = 14534 }
$ports
$ports['sql1']
$ports.sql2
$ports.ContainsKey('sql3')
$ports['sql3'] = 1433
$ports.Keys

# No order is kept, and the order changes from one session to the next; [ordered] keeps it.
@{ Name = 'sql1'; SqlInstance = 'localhost,14533'; Environment = 'Production'; Owner = 'planning' }
[ordered]@{ Name = 'sql1'; SqlInstance = 'localhost,14533'; Environment = 'Production'; Owner = 'planning' }

# $_ and $PSItem: the current object, in a script block of the pipeline.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Where-Object -FilterScript { $PSItem.Length -gt 2.4MB }
