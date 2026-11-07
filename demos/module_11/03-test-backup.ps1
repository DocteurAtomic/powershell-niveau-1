# Module 11, clip 11.3: Test-DbaLastBackup.
# Run from the root of the clone, one command at a time at the console, after clip 11.1. Each
# test restores a copy named m11_test_<database> on the other instance, checks it with
# DBCC CHECKDB and drops it.

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

# The form of the documentation: from the history of sql2, restored on sql1.
Test-DbaLastBackup -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Destination 'localhost,14533' -DestinationSqlCredential $cred -Prefix m11_test_ -WhatIf
$test = Test-DbaLastBackup -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Destination 'localhost,14533' -DestinationSqlCredential $cred -Prefix m11_test_
$test
$?

# The form that works between two instances of the lab: the file itself, with -Path.
$file = Get-DbaDbBackupHistory -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Last | Select-Object -ExpandProperty Path
Test-DbaLastBackup -Path $file -Destination 'localhost,14533' -DestinationSqlCredential $cred -Prefix m11_test_ -WhatIf
$test = Test-DbaLastBackup -Path $file -Destination 'localhost,14533' -DestinationSqlCredential $cred -Prefix m11_test_
$test | Format-List -Property SourceServer, TestServer, Database, FileExists, RestoreResult, DbccResult, RestoreElapsed, DbccElapsed, BackupFiles
$test.DbccOutput | Select-Object -First 3
Get-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Database m11_test_Finance

# PachadataTraining, from sql1 to sql2, the instance with one processor.
$file = Get-DbaDbBackupHistory -SqlInstance 'localhost,14533' -SqlCredential $cred -Database PachadataTraining -Last | Select-Object -ExpandProperty Path
Measure-Command -Expression { $test = Test-DbaLastBackup -Path $file -Destination 'localhost,14534' -DestinationSqlCredential $cred -Prefix m11_test_ } | Select-Object -Property TotalSeconds
$test | Format-Table -Property Database, Size, RestoreResult, DbccResult, RestoreElapsed, DbccElapsed

# The answer to the team: every user database backed up, restored on the other instance, checked.
./demos/module_11/05-verified-backups.ps1 | Format-Table -Property Instance, Database, TestedOn, CompressedMB, Restore, Dbcc, Verified
