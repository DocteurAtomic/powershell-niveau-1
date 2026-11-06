# Module 1, clip 1.4: the aliases on Linux, and the answer to the request.
# Run from the root of the clone, one command at a time at the console.
# ls -l is the ls program of Linux and macOS; on Windows, ls is an alias of Get-ChildItem
# and ls -l fails.

# The aliases of the session, then the two aliases of Get-ChildItem.
Get-Alias
Get-Alias -Definition Get-ChildItem

# On Linux and macOS, ls is not an alias: it is the program /usr/bin/ls.
Get-Alias -Name ls
Get-Command -Name ls

# The same folder: lines of text from ls, objects from dir.
ls lab/backups/sql1/Finance/FULL
dir lab/backups/sql1/Finance/FULL

# ls -l writes one line of text per file, after a first line "total".
ls -l lab/backups/sql1/Finance/FULL

# Measure-Object sums the Length of what it receives: bytes for files, characters for text.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL | Measure-Object -Property Length -Sum
ls -l lab/backups/sql1/Finance/FULL | Measure-Object -Property Length -Sum

# The answer to the team: how many backup files, and how many bytes.
Get-ChildItem -Path lab/backups -Recurse -File | Measure-Object -Property Length -Sum
