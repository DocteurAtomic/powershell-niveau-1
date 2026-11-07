# Module 5, clip 5.1: a first script, the last full backup of each database of sql1.
# The path below is relative to the current location: the script works from the root of
# the clone, and nowhere else. 02-last-full-scriptroot.ps1 is the version that works from
# anywhere.
Get-ChildItem -Path lab/backups/sql1 -Recurse -File -Filter *_FULL_* |
    Group-Object -Property { $_.Directory.Parent.Name } |
    Select-Object -Property @{ Name = 'Database'; Expression = { $_.Name } },
        @{ Name = 'LastFull'; Expression = { ($_.Group | Measure-Object -Property LastWriteTime -Maximum).Maximum } }
