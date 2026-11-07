# Module 12, clip 12.1: copy a database.
# Run from the root of the clone, one command at a time at the console, after
# ./demos/module_12/00-setup.ps1 (the planning application on sql1). The copy goes to sql2
# through the volume both instances share; ./demos/module_12/99-cleanup.ps1 removes it.

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sql1 = 'localhost,14533'
$sql2 = 'localhost,14534'

# What the planning application uses on sql1: a database, a login, a job.
Get-DbaDatabase -SqlInstance $sql1 -SqlCredential $cred -Database Planning | Format-List -Property Name, Owner, RecoveryModel, IsReadCommittedSnapshotOn, Size
Get-DbaLogin -SqlInstance $sql1 -SqlCredential $cred -Login planning_app | Format-Table -Property SqlInstance, Name, LoginType, DefaultDatabase
Get-DbaAgentJob -SqlInstance $sql1 -SqlCredential $cred -Job 'Planning - nightly purge' | Format-Table -Property SqlInstance, Name, IsEnabled, OwnerLoginName, NextRunDate

# The database first, with -WhatIf: a copy-only backup to the shared folder, restored on sql2.
Copy-DbaDatabase -Source $sql1 -SourceSqlCredential $cred -Destination $sql2 -DestinationSqlCredential $cred -Database Planning -BackupRestore -SharedPath /var/opt/mssql/backup -WhatIf
$copy = Copy-DbaDatabase -Source $sql1 -SourceSqlCredential $cred -Destination $sql2 -DestinationSqlCredential $cred -Database Planning -BackupRestore -SharedPath /var/opt/mssql/backup
$copy | Format-List -Property SourceServer, DestinationServer, Name, Status, Notes

# What came with the database, and the backup it went through.
Get-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database Planning | Format-List -Property Name, Owner, RecoveryModel, IsReadCommittedSnapshotOn, Size
Get-DbaDbBackupHistory -SqlInstance $sql1 -SqlCredential $cred -Database Planning -IncludeCopyOnly | Format-List -Property Database, Type, IsCopyOnly, Path

# What did not come: the login. The user of the database has no login on sql2.
Get-DbaDbUser -SqlInstance $sql2 -SqlCredential $cred -Database Planning -ExcludeSystemUser | Format-Table -Property SqlInstance, Database, Name, Login, LoginType
Get-DbaDbOrphanUser -SqlInstance $sql2 -SqlCredential $cred | Format-Table -Property SqlInstance, DatabaseName, User

# A second copy does not replace the first one: read Status.
Copy-DbaDatabase -Source $sql1 -SourceSqlCredential $cred -Destination $sql2 -DestinationSqlCredential $cred -Database Planning -BackupRestore -SharedPath /var/opt/mssql/backup | Format-Table -Property Name, Status, Notes
