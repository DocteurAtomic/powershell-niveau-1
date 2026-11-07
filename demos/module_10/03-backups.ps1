# Module 10, clip 10.3: the backups and their age.
# Run from the root of the clone, one command at a time at the console, after
# ./demos/module_10/00-setup.ps1 (Finance on sql2, backed up once in full).

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$lab = 'localhost,14533', 'localhost,14534'

# The last backup of each database, read from msdb.
Get-DbaLastBackup -SqlInstance $lab -SqlCredential $cred | Format-Table -Property SqlInstance, Database, LastFullBackup, LastDiffBackup, LastLogBackup
Get-DbaLastBackup -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance | Select-Object -Property *
Get-DbaDbBackupHistory -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance | Format-List -Property Database, Type, Start, End, TotalSize, Path

# The age that dbatools computes uses the clock of this computer; the instance runs in UTC.
Get-Date
Invoke-DbaQuery -SqlInstance 'localhost,14534' -SqlCredential $cred -Query 'SELECT SYSDATETIME() AS ServerTime;'

# The age computed from the clock of the instance, and a threshold.
$server = Connect-DbaInstance -SqlInstance 'localhost,14534' -SqlCredential $cred
$now = (Invoke-DbaQuery -SqlInstance $server -Query 'SELECT SYSDATETIME() AS Now;').Now
$age = @{ Name = 'AgeHours'; Expression = { if ($null -eq $_.LastFullBackup) { $null } else { [math]::Round(($now - $_.LastFullBackup).TotalHours, 1) } } }
$status = @{ Name = 'BackupStatus'; Expression = { if ($null -eq $_.LastFullBackup) { 'never' } elseif (($now - $_.LastFullBackup).TotalHours -gt 24) { 'late' } else { 'ok' } } }
Get-DbaLastBackup -SqlInstance $server | Select-Object -Property Database, LastFullBackup, $age, $status

# The disk space: CIM, which Linux does not have.
Get-DbaDiskSpace -ComputerName localhost
