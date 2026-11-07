# Module 5, clip 5.5: the same report written as text with Write-Host. It shows on the
# screen, and nothing comes out of the script: no object to sort, filter or export.
$backups = Join-Path -Path $PSScriptRoot -ChildPath '../../lab/backups/sql1'

foreach ($database in Get-ChildItem -Path $backups -Directory) {
    $last = Get-ChildItem -Path $database.FullName -Recurse -File -Include *.bak, *.trn |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1
    Write-Host "$($database.Name): last backup $($last.Name)"
}
