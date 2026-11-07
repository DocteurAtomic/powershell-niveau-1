# Exercise of module 11. Load the function with:
#   . ./exercises/module_11/Test-BackupRestore.ps1
# then try it with -WhatIf first: Test-BackupRestore -WhatIf

function Test-BackupRestore {
    <#
    .SYNOPSIS
    Backs up a database, restores it as a copy on another instance, compares a table and drops the copy.

    .DESCRIPTION
    Exercise of module 11. Write the body of the function:

    1. a full, compressed backup of -Database on -SqlInstance into -BackupFolder, in a file
       whose name starts with m11_ (Backup-DbaDatabase);
    2. its restore on -Destination under the name -CopyName, with the physical files renamed
       after the copy (Restore-DbaDatabase);
    3. the rows of -Table counted in the database and in the copy (Invoke-DbaQuery and the
       query $count below);
    4. the copy dropped (Remove-DbaDatabase).

    Return one object with the properties Database, Copy, Destination, BackupFile,
    SourceRows, CopyRows, RowsMatch and CopyRemoved. With -WhatIf, the function must say what
    it would do and do nothing: no backup, no restore.

    .PARAMETER SqlInstance
    The instance of the database to back up.

    .PARAMETER Destination
    The instance where the copy is restored.

    .PARAMETER Database
    The database to back up.

    .PARAMETER Table
    The table whose rows are counted, as schema.table.

    .PARAMETER CopyName
    The name of the copy on -Destination.

    .PARAMETER BackupFolder
    The folder of the backup, as the instances see it.

    .PARAMETER SqlCredential
    The login for both instances; the secret sql-lab of the vault PachaOps by default.

    .EXAMPLE
    Test-BackupRestore -WhatIf

    .EXAMPLE
    Test-BackupRestore -Database Finance -Table dbo.LedgerEntry -CopyName m11_FinanceCopy
    #>
    [CmdletBinding()]
    param(
        [string] $SqlInstance = 'localhost,14534',
        [string] $Destination = 'localhost,14533',
        [string] $Database = 'Finance',
        [string] $Table = 'dbo.LedgerEntry',
        [ValidatePattern('^m11_')]
        [string] $CopyName = 'm11_FinanceCopy',
        [string] $BackupFolder = '/var/opt/mssql/backup',
        [pscredential] $SqlCredential = (Get-Secret -Name sql-lab -Vault PachaOps)
    )
    $ErrorActionPreference = 'Stop'
    Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

    # The count, with the name of the table passed as a parameter, not concatenated (module 9):
    # Invoke-DbaQuery ... -Query $count -SqlParameter @{ table = $Table }
    $count = @'
DECLARE @sql nvarchar(max) = N'SELECT COUNT_BIG(*) AS Rows FROM '
    + QUOTENAME(PARSENAME(@table, 2)) + N'.' + QUOTENAME(PARSENAME(@table, 1)) + N';';
EXEC sys.sp_executesql @sql;
'@

    # Your code here.
}
