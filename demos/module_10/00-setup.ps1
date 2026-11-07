<#
.SYNOPSIS
Creates the Finance database on sql2, the lab state that modules 10 to 12 assume.

.DESCRIPTION
Module 10 inventories both instances of the lab. On sql2 (localhost,14534), it expects a
database Finance in the full recovery model, backed up once in full and never in log, so
that the morning report has a database to flag. Modules 11 and 12 back up, restore and copy
the same database.

The script creates the PachaOps vault and its sql-lab secret first when they are missing
(./demos/module_09/00-setup.ps1), then the database, a table dbo.LedgerEntry of 1,000
rows, and one full backup on the shared volume, /var/opt/mssql/backup/m10_Finance_full.bak.
It does nothing when Finance already exists. ./demos/module_10/99-cleanup.ps1 removes all
of it.

.EXAMPLE
./demos/module_10/00-setup.ps1
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot '..' 'module_09' '00-setup.ps1') | Out-Null
$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sql2 = 'localhost,14534'

if (Get-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database Finance -EnableException) {
    'ok    the database Finance already exists on sql2'
    return
}

New-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Name Finance -RecoveryModel Full -EnableException | Out-Null
$table = @'
CREATE TABLE dbo.LedgerEntry (
    LedgerEntryId int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_LedgerEntry PRIMARY KEY,
    EntryDate date NOT NULL,
    Account char(6) NOT NULL,
    Amount decimal(12, 2) NOT NULL
);
INSERT INTO dbo.LedgerEntry (EntryDate, Account, Amount)
SELECT DATEADD(day, -(n.Number % 365), '20261102'),
       CASE n.Number % 3 WHEN 0 THEN '411000' WHEN 1 THEN '512000' ELSE '706000' END,
       CAST((n.Number * 37) % 5000 AS decimal(12, 2)) + 0.5
FROM (SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Number
      FROM sys.all_objects) AS n;
'@
Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Database Finance -Query $table -EnableException
Backup-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database Finance -Type Full `
    -FilePath /var/opt/mssql/backup/m10_Finance_full.bak -EnableException | Out-Null
'ok    the database Finance is created on sql2, in full recovery, backed up once in full'
