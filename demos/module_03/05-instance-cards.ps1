# Module 3, clip 3.4: one card per instance of the lab, the answer to the team.
# Unlike the other scripts of this folder, this one runs as a whole, from the root of the
# clone, and returns only instance cards:
#   ./demos/module_03/05-instance-cards.ps1
# The video uses backup files created for 2 November 2026, and the age of the last full
# backup is computed for that day. For your own files, write (Get-Date) instead.
$referenceDate = Get-Date -Date '2026-11-02'

$sql1Instance = 'localhost,14533'
$sql1LastFull = Get-ChildItem -Path lab/backups/sql1 -Recurse -File -Filter *_FULL_* |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -First 1

[pscustomobject]@{
    Name               = 'sql1'
    SqlInstance        = $sql1Instance
    Port               = [int]($sql1Instance -split ',')[1]
    Environment        = 'Production'
    Owner              = 'planning'
    DatabaseCount      = @(Get-ChildItem -Path lab/backups/sql1 -Directory).Count
    LastFullBackup     = $sql1LastFull.LastWriteTime
    FullBackupAgeHours = [int]($referenceDate - $sql1LastFull.LastWriteTime).TotalHours
}

# No file of sql2 on the backup share: its backup properties stay empty.
$sql2Instance = 'localhost,14534'
[pscustomobject]@{
    Name               = 'sql2'
    SqlInstance        = $sql2Instance
    Port               = [int]($sql2Instance -split ',')[1]
    Environment        = 'Production'
    Owner              = 'planning'
    DatabaseCount      = 0
    LastFullBackup     = $null
    FullBackupAgeHours = $null
}
