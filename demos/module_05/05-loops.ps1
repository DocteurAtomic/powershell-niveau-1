# Module 5, clip 5.4: foreach and ForEach-Object, for, while, break and continue.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# The foreach statement: one object per database folder.
$databases = Get-ChildItem -Path lab/backups/sql1 -Directory
foreach ($database in $databases) {
    [pscustomobject]@{
        Database = $database.Name
        Files    = @(Get-ChildItem -Path $database.FullName -Recurse -File).Count
    }
}
# Typed in the video, not run here: a statement cannot be piped, this is a parse error.
#   foreach ($database in $databases) { $database.Name } | Sort-Object
$rows = foreach ($database in $databases) {
    [pscustomobject]@{
        Database = $database.Name
        Files    = @(Get-ChildItem -Path $database.FullName -Recurse -File).Count
    }
}
$rows | Sort-Object -Property Files -Descending

# The ForEach-Object command: the same objects, in the pipeline.
$databases | ForEach-Object -Process {
    [pscustomobject]@{
        Database = $_.Name
        Files    = @(Get-ChildItem -Path $_.FullName -Recurse -File).Count
    }
} | Sort-Object -Property Files -Descending

# for: the files written on each of the seven days before 2 November.
$reference = Get-Date -Date '2026-11-02'
$files = Get-ChildItem -Path lab/backups/sql1 -Recurse -File -Include *.bak, *.trn
for ($day = 1; $day -le 7; $day++) {
    $date = $reference.AddDays(-$day)
    [pscustomobject]@{
        Date  = '{0:yyyy-MM-dd}' -f $date
        Day   = $date.DayOfWeek
        Files = @($files | Where-Object -FilterScript { $_.LastWriteTime.Date -eq $date }).Count
    }
}

# while: back to the last Sunday, the day of the full backups.
$sunday = $reference
while ($sunday.DayOfWeek -ne 'Sunday') {
    $sunday = $sunday.AddDays(-1)
}
$sunday

# continue skips the rest of one turn; break leaves the loop.
foreach ($file in Get-ChildItem -Path lab/backups/sql1/Finance/FULL -File) {
    if ($file.Extension -ne '.bak') { continue }
    $file.Name
}
foreach ($file in Get-ChildItem -Path lab/backups/sql1/Planning/DIFF -File | Sort-Object -Property LastWriteTime -Descending) {
    if ($file.Length -eq 0) {
        "First empty file: $($file.Name)"
        break
    }
}
