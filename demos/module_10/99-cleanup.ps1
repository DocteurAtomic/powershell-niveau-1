<#
ci: skip (modules 11 and 12 use the Finance database that 00-setup.ps1 creates)
.SYNOPSIS
Removes what ./demos/module_10/00-setup.ps1 created on sql2.

.DESCRIPTION
Drops the database Finance from sql2 (localhost,14534), deletes its backup and restore
history from msdb and the backup file /var/opt/mssql/backup/m10_Finance_full.bak. Run it
only to start module 10 again from a clean lab: modules 11 and 12 use Finance.
Shown first with -WhatIf, like every command of the course that removes something.

.EXAMPLE
./demos/module_10/99-cleanup.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()
$ErrorActionPreference = 'Stop'
$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sql2 = 'localhost,14534'
$file = '/var/opt/mssql/backup/m10_Finance_full.bak'

if ($PSCmdlet.ShouldProcess("$sql2, database Finance, its history and $file", 'Remove')) {
    Remove-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database Finance -Confirm:$false | Out-Null
    $history = @'
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'Finance';
EXEC master.sys.xp_delete_files @file;
'@
    Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Query $history -SqlParameter @{ file = $file } -EnableException
    'ok    Finance, its history and its backup file are removed from sql2'
}
