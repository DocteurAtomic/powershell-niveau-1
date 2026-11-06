# Module 3, clip 3.1: variables and types.
# Run from the root of the clone, one command at a time at the console (or select a line
# and press F8 in VS Code). The video uses backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# A variable: a name after $, a value after =. Its type is the type of the value.
$instance = 'sql1'
$port = 14533
$instance.GetType()
$port.GetType().FullName
(2.33).GetType().FullName

# A quoted number is a string: + then concatenates or adds, depending on the left operand.
$text = '14533'
$text + 1
1 + $text

# A cast converts the value; a typed variable converts every value it receives.
[int]$text + 1
[int]'abc'
[int]$typedPort = '14533'
$typedPort = 'abc'
$typedPort

# Dates: a [datetime], its methods, and a [timespan] when you subtract two dates.
$reference = Get-Date -Date '2026-11-02'
$reference.GetType().FullName
$reference.AddDays(-7)
$lastFull = (Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -First 1).LastWriteTime
$lastFull
$age = $reference - $lastFull
$age
$age.TotalHours

# The culture changes the display, and the reading of a date by a cast or by a cmdlet.
[cultureinfo]::CurrentCulture = 'fr-FR'
$reference
[datetime]'2026-11-02'
[datetime]'02/11/2026'
Get-Date -Date '02/11/2026'
[cultureinfo]::CurrentCulture = 'en-US'

# $null: a variable that was never assigned, and why $null goes on the left.
$nothing
$null -eq $nothing
$values = 14533, $null, 14534
$values -ne $null
$null -ne $values
