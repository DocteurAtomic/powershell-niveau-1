<#
.SYNOPSIS
Moves the finance report application from sql2 to sql1: the database Finance, then the login finance_report.

.DESCRIPTION
Exercise of module 12. The finance report reads the database Finance with the SQL login
finance_report. Both move from sql2 (localhost,14534) to sql1 (localhost,14533), and the
script proves that the application can work there: it reads a table of the copy on the
destination, connected as finance_report, with the password kept in the vault (secret
finance-report, created by ./demos/module_12/00-setup.ps1).

With -WhatIf, the script says what it would do and copies nothing.

Returns one object: Database, Login, DatabaseStatus and LoginStatus (the Status of the two
copies), SourceRows (the rows of -Table on the source), Rows (the rows of -Table on the
destination, read as the login), Orphans (the number of orphaned users of the database on
the destination) and Verified ($true when both copies are Successful, the two counts are
equal and there is no orphaned user).

.EXAMPLE
./exercises/module_12/Move-FinanceApp.ps1 -WhatIf

.EXAMPLE
./exercises/module_12/Move-FinanceApp.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $Source = 'localhost,14534',
    [string] $Destination = 'localhost,14533',
    [string] $Database = 'Finance',
    [string] $Login = 'finance_report',
    [string] $LoginSecret = 'finance-report',
    [string] $Table = 'dbo.LedgerEntry',
    [string] $SharedPath = '/var/opt/mssql/backup'
)
$ErrorActionPreference = 'Stop'

$cred = Get-Secret -Name sql-lab -Vault PachaOps
$app = Get-Secret -Name $LoginSecret -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$count = "SELECT COUNT_BIG(*) AS Rows FROM $Table;"

# Write the body of the script:
# 1. copy -Database from -Source to -Destination, by a backup in -SharedPath;
# 2. copy -Login, with its password and its SID;
# 3. count the rows of -Table in the database on the source, with $cred;
# 4. count them in the copy, on the destination, connected with $app;
# 5. count the orphaned users of the database on the destination;
# 6. return the object of the description.
# With -WhatIf, nothing may be copied: remember module 11.
