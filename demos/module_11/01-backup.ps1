# Module 11, clip 11.1: Backup-DbaDatabase.
# Run from the root of the clone, one command at a time at the console, after
# ./demos/module_10/00-setup.ps1 (the secret sql-lab and the database Finance on sql2).
# The backups are written to /var/opt/mssql/backup, the volume both instances share, in files
# whose name starts with m11_; ./demos/module_11/99-cleanup.ps1 removes them.

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$lab = 'localhost,14533', 'localhost,14534'

# -WhatIf first: without -Path, the backup goes to the default backup folder of the instance.
Backup-DbaDatabase -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Type Full -CompressBackup -WhatIf
Get-DbaInstanceProperty -SqlInstance $lab -SqlCredential $cred -InstanceProperty BackupDirectory | Format-Table -Property SqlInstance, Name, Value
Backup-DbaDatabase -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Type Full -CompressBackup -Path /var/opt/mssql/backup -WhatIf

# The name of the file: the tokens are replaced only with -ReplaceInName.
Backup-DbaDatabase -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Type Full -CompressBackup -Path /var/opt/mssql/backup -FilePath 'm11_dbname_backuptype_timestamp.bak' -OutputScriptOnly
Backup-DbaDatabase -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Type Full -CompressBackup -Path /var/opt/mssql/backup -FilePath 'm11_servername_dbname_backuptype_timestamp.bak' -ReplaceInName -OutputScriptOnly

# The backup, and the object it returns.
$backup = Backup-DbaDatabase -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Type Full -CompressBackup -Path /var/opt/mssql/backup -FilePath 'm11_dbname_timestamp.bak' -ReplaceInName
$backup
$backup | Format-List -Property Database, Type, TotalSize, CompressedBackupSize, CompressionRatio, Duration, BackupPath

# Every user database of both instances: -SqlInstance takes one instance, the pipeline takes the databases.
Backup-DbaDatabase -SqlInstance $lab -SqlCredential $cred -Database Finance -WhatIf
$backups = Get-DbaDatabase -SqlInstance $lab -SqlCredential $cred -ExcludeSystem | Backup-DbaDatabase -Type Full -CompressBackup -Path /var/opt/mssql/backup -FilePath 'm11_dbname_backuptype_timestamp.bak' -ReplaceInName
$backups | Format-Table -Property SqlInstance, Database, TotalSize, CompressedBackupSize, Duration, BackupFile
