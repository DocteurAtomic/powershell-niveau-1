<#
.SYNOPSIS
Moves the finance report application from sql2 to sql1: the database Finance, then the login finance_report.

.DESCRIPTION
Solution of the exercise of module 12. The database first, so that the login finds its user
when it arrives; then the login, copied with its hashed password and its SID, so that the
user of the database is not orphaned; then the proof: the table read on the destination,
connected as the login, with the password of the vault.

One question, $PSCmdlet.ShouldProcess, for the whole move: the dbatools commands do not see
the -WhatIf of the script (module 8, measured at module 11).

.EXAMPLE
./exercises/module_12/solution/Move-FinanceApp.ps1 -WhatIf

.EXAMPLE
./exercises/module_12/solution/Move-FinanceApp.ps1
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

if (-not $PSCmdlet.ShouldProcess($Destination, "Copy the database $Database and the login $Login from $Source")) {
    return
}

$databaseCopy = Copy-DbaDatabase -Source $Source -SourceSqlCredential $cred -Destination $Destination -DestinationSqlCredential $cred `
    -Database $Database -BackupRestore -SharedPath $SharedPath -Confirm:$false -EnableException
$loginCopy = Copy-DbaLogin -Source $Source -SourceSqlCredential $cred -Destination $Destination -DestinationSqlCredential $cred `
    -Login $Login -Confirm:$false -EnableException

$sourceRows = (Invoke-DbaQuery -SqlInstance $Source -SqlCredential $cred -Database $Database -Query $count -EnableException).Rows
# Connected as the application: the login, its password and its user must all be right.
$rows = try {
    (Invoke-DbaQuery -SqlInstance $Destination -SqlCredential $app -Database $Database -Query $count -EnableException).Rows
}
catch {
    Write-Warning -Message "$Login cannot read $Table in $Database on ${Destination}: $($_.Exception.Message)"
    $null
}
$orphans = @(Get-DbaDbOrphanUser -SqlInstance $Destination -SqlCredential $cred -Database $Database -EnableException).Count

[pscustomobject]@{
    Database       = $Database
    Login          = $Login
    DatabaseStatus = $databaseCopy.Status
    LoginStatus    = $loginCopy.Status
    SourceRows     = $sourceRows
    Rows           = $rows
    Orphans        = $orphans
    Verified       = $databaseCopy.Status -eq 'Successful' -and $loginCopy.Status -eq 'Successful' -and
        $null -ne $rows -and $rows -eq $sourceRows -and $orphans -eq 0
}
