# Exercise of module 11, solution. Load the function with:
#   . ./exercises/module_11/solution/Test-BackupRestore.ps1

function Test-BackupRestore {
    <#
    .SYNOPSIS
    Backs up a database, restores it as a copy on another instance, compares a table and drops the copy.

    .DESCRIPTION
    Takes a full, compressed, copy-only backup of -Database on -SqlInstance into -BackupFolder,
    a folder that both instances can read. Restores it on -Destination under the name
    -CopyName, with the physical files renamed after the copy. Counts the rows of -Table in the
    database and in the copy, then drops the copy.

    Returns one object: the database, the copy, the backup file, the two row counts, whether
    they match, and whether the copy is gone. With -WhatIf, says what it would do and does
    nothing: no backup, no restore.

    .PARAMETER SqlInstance
    The instance of the database to back up.

    .PARAMETER Destination
    The instance where the copy is restored.

    .PARAMETER Database
    The database to back up.

    .PARAMETER Table
    The table whose rows are counted, as schema.table.

    .PARAMETER CopyName
    The name of the copy on -Destination. The function refuses to run when it already exists.

    .PARAMETER BackupFolder
    The folder of the backup, as the instances see it.

    .PARAMETER SqlCredential
    The login for both instances; the secret sql-lab of the vault PachaOps by default.

    .EXAMPLE
    Test-BackupRestore -WhatIf

    .EXAMPLE
    Test-BackupRestore -Database Finance -Table dbo.LedgerEntry -CopyName m11_FinanceCopy
    #>
    [CmdletBinding(SupportsShouldProcess)]
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

    # The count, with the name of the table passed as a parameter, not concatenated (module 9).
    $count = @'
DECLARE @sql nvarchar(max) = N'SELECT COUNT_BIG(*) AS Rows FROM '
    + QUOTENAME(PARSENAME(@table, 2)) + N'.' + QUOTENAME(PARSENAME(@table, 1)) + N';';
EXEC sys.sp_executesql @sql;
'@

    if (Get-DbaDatabase -SqlInstance $Destination -SqlCredential $SqlCredential -Database $CopyName) {
        throw "The database $CopyName already exists on ${Destination}: drop it first."
    }

    # One question for the whole test: the dbatools commands below run in a module, where
    # -WhatIf given to this function does not reach them.
    $target = "$Database on $SqlInstance, copy $CopyName on $Destination"
    if (-not $PSCmdlet.ShouldProcess($target, 'Back up, restore as a copy, compare and drop the copy')) {
        return
    }

    $backup = Backup-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Type Full -CopyOnly -CompressBackup `
        -Path $BackupFolder -FilePath 'm11_exercise_dbname_timestamp.bak' -ReplaceInName -EnableException
    Restore-DbaDatabase -SqlInstance $Destination -SqlCredential $SqlCredential -Path $backup.BackupPath -DatabaseName $CopyName `
        -ReplaceDbNameInFile -EnableException | Out-Null

    $sourceRows = (Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $count -SqlParameter @{ table = $Table } -EnableException).Rows
    $copyRows = (Invoke-DbaQuery -SqlInstance $Destination -SqlCredential $SqlCredential -Database $CopyName -Query $count -SqlParameter @{ table = $Table } -EnableException).Rows

    Remove-DbaDatabase -SqlInstance $Destination -SqlCredential $SqlCredential -Database $CopyName -Confirm:$false -EnableException | Out-Null
    $removed = $null -eq (Get-DbaDatabase -SqlInstance $Destination -SqlCredential $SqlCredential -Database $CopyName)

    [pscustomobject]@{
        Database    = $Database
        Copy        = $CopyName
        Destination = $Destination
        BackupFile  = $backup.BackupPath
        SourceRows  = $sourceRows
        CopyRows    = $copyRows
        RowsMatch   = $sourceRows -eq $copyRows
        CopyRemoved = $removed
    }
}
