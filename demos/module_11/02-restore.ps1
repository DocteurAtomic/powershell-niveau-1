# Module 11, clip 11.2: Restore-DbaDatabase.
# Run from the root of the clone, one command at a time at the console, after clip 11.1 (or
# after ./demos/module_10/00-setup.ps1 alone: the last backup of Finance is then the one of
# module 10). The copy m11_FinanceCopy is restored on sql1 and dropped at the end.

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

# The file of the last full backup of Finance, read from the history of sql2.
$file = Get-DbaDbBackupHistory -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Last | Select-Object -ExpandProperty Path
$file

# The T-SQL first: -OutputScriptOnly restores nothing.
Restore-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Path $file -DatabaseName m11_FinanceCopy -OutputScriptOnly
Restore-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Path $file -DatabaseName m11_FinanceCopy -ReplaceDbNameInFile -OutputScriptOnly
Restore-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Path $file -DatabaseName m11_FinanceCopy -ReplaceDbNameInFile -DestinationDataDirectory /var/opt/mssql/data/copies -OutputScriptOnly

# A folder instead of a file: every database found in it, under its own name.
Restore-DbaDatabase -SqlInstance 'localhost,14534' -SqlCredential $cred -Path /var/opt/mssql/backup -OutputScriptOnly
Restore-DbaDatabase -SqlInstance 'localhost,14534' -SqlCredential $cred -Path /var/opt/mssql/backup -DatabaseName m11_Copy -OutputScriptOnly

# -WhatIf, then the restore, and the copy read.
Restore-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Path $file -DatabaseName m11_FinanceCopy -ReplaceDbNameInFile -WhatIf
$restore = Restore-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Path $file -DatabaseName m11_FinanceCopy -ReplaceDbNameInFile
$restore | Format-List -Property SqlInstance, Database, BackupFile, RestoreComplete, RestoredFileFull, DatabaseRestoreTime
$count = 'SELECT COUNT(*) AS Rows FROM dbo.LedgerEntry;'
(Invoke-DbaQuery -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance -Query $count).Rows
(Invoke-DbaQuery -SqlInstance 'localhost,14533' -SqlCredential $cred -Database m11_FinanceCopy -Query $count).Rows

# The same name again: refused without -WithReplace, which replaces the database in place.
Restore-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Path $file -DatabaseName m11_FinanceCopy -ReplaceDbNameInFile
Restore-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Path $file -DatabaseName m11_FinanceCopy -ReplaceDbNameInFile -WithReplace -OutputScriptOnly

# The copy dropped, -WhatIf first.
Remove-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Database m11_FinanceCopy -WhatIf
Remove-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Database m11_FinanceCopy -Confirm:$false | Format-Table -Property SqlInstance, Database, Status
