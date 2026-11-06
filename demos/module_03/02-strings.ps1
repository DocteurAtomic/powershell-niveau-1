# Module 3, clip 3.2: strings.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# Single quotes: verbatim. Double quotes: variables are replaced by their value.
$database = 'Finance'
'Database: $database'
"Database: $database"

# A property inside double quotes needs a subexpression, $( ).
$file = Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Select-Object -First 1
"Size: $file.Length"
"Size: $($file.Length) bytes"

# The format operator: a template on the left, the values on the right.
'{0}: {1:N2} MB' -f $file.Name, ($file.Length / 1MB)

# A here-string: several lines, quotes kept as they are.
$message = @"
Backup check for "$database"
Oldest full backup: $($file.Name)
Written on: $($file.LastWriteTime)
"@
$message

# Split, join, replace, match.
$file.Name -split '_'
($file.Name -split '_')[1]
'localhost,14533' -split ','
[int]('localhost,14533' -split ',')[1]
'sql1', 'Finance', 'FULL' -join '/'
$file.Name -replace 'FULL', 'DIFF'
$file.Name -match '_(\d{8})_'
$Matches
$Matches[1]
