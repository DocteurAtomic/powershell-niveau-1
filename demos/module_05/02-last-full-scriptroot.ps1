# Module 5, clip 5.1: the same script, with a path built from $PSScriptRoot, the folder of
# the script itself. It gives the same result whatever the current location.
$backups = Join-Path -Path $PSScriptRoot -ChildPath '../../lab/backups/sql1'

Get-ChildItem -Path $backups -Recurse -File -Filter *_FULL_* |
    Group-Object -Property { $_.Directory.Parent.Name } |
    Select-Object -Property @{ Name = 'Database'; Expression = { $_.Name } },
        @{ Name = 'LastFull'; Expression = { ($_.Group | Measure-Object -Property LastWriteTime -Maximum).Maximum } }
