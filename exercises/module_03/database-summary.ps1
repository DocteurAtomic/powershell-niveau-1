# Exercise of module 3, part 1.
# One object per database of sql1, from the backup files under lab/backups/sql1 (the files
# whose name starts with sql1_; the README of Finance is not a backup), each with four
# properties:
#   Database    the name of the database, taken from the path or from the file name
#   FileCount   the number of backup files of the database
#   SizeMB      their total size in megabytes, rounded to one decimal
#   LastBackup  the date of the most recent one, as a [datetime], not as a string
# Write a single pipeline below, run from the root of the clone, then run:
#   ./exercises/module_03/check.ps1
