# Module 5, clip 5.3: if, elseif, else, then switch, on the backups of sql1.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026, and a report written at 8 AM that day:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

$maxAgeHours = 24
$reference = Get-Date -Date '2026-11-02 08:00'

# The last backup of Finance, and its status.
$last = Get-ChildItem -Path lab/backups/sql1/Finance -Recurse -File -Include *.bak, *.trn |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -First 1
$last.Name
($reference - $last.LastWriteTime).TotalHours
if (($reference - $last.LastWriteTime).TotalHours -gt $maxAgeHours) { 'Late' } else { 'OK' }

# A database folder without any backup file: the first test must be $null.
New-Item -Path lab/backups/sql1/Archive -ItemType Directory | Out-Null
$last = Get-ChildItem -Path lab/backups/sql1/Archive -Recurse -File -Include *.bak, *.trn |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -First 1
$null -eq $last
($reference - $last.LastWriteTime).TotalHours
# At the console, elseif and else go on the line of the closing brace: a line that ends
# with } ends the if statement.
$status = if ($null -eq $last) {
    'Missing'
} elseif (($reference - $last.LastWriteTime).TotalHours -gt $maxAgeHours) {
    'Late'
} else {
    'OK'
}
$status
Remove-Item -Path lab/backups/sql1/Archive

# switch on the extension, then switch -Wildcard on the name.
$file = Get-Item -Path lab/backups/sql1/Finance/FULL/README-restore.txt
switch ($file.Extension) {
    '.bak'  { 'Full or differential backup' }
    '.trn'  { 'Log backup' }
    default { 'Not a backup' }
}
$names = 'sql1_Finance_FULL_20261101_010000.bak', 'sql1_Planning_DIFF_20261102_010000.bak',
    'sql1_PachadataTraining_LOG_20261101_220000.trn', 'README-restore.txt'
switch -Wildcard ($names) {
    '*_FULL_*' { 'FULL' }
    '*_DIFF_*' { 'DIFF' }
    '*.trn'    { 'LOG' }
    default    { 'Not a backup' }
}
# Every clause that matches runs, not only the first one.
switch -Wildcard ('sql1_Finance_FULL_20261101_010000.bak') {
    '*_FULL_*' { 'FULL' }
    '*.bak'    { 'Backup file' }
}

# The failed backup of Planning: a .bak file of 0 bytes.
$empty = Get-ChildItem -Path lab/backups/sql1/Planning -Recurse -File |
    Where-Object -Property Length -EQ -Value 0
$empty.Name
if ($empty.Length -eq 0 -and $empty.Extension -eq '.bak') { 'Empty backup file' }
