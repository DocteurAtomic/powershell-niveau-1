<#
.SYNOPSIS
Lists the user databases of every instance of an inventory, with their last full backup.

.DESCRIPTION
Reads the inventory, connects to each instance with the sql-lab secret of the PachaOps
vault, and returns one object per user database. An instance that does not answer is
reported by a warning and skipped.

Solution of the exercise of module 10: each object also has RecoveryModel (a string such
as Full or Simple), SizeMB (a number) and LogBackupMissing ($true for a database in the full
recovery model that has never had a log backup).

.PARAMETER InventoryPath
The CSV inventory, with the columns Name and SqlInstance.

.PARAMETER ConnectTimeout
Seconds to wait for each instance before skipping it.

.EXAMPLE
./exercises/module_10/solution/Get-DatabaseInventory.ps1 -InventoryPath data/instances.csv | Format-Table
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $InventoryPath,
    [ValidateRange(1, 60)]
    [int] $ConnectTimeout = 5
)
$ErrorActionPreference = 'Stop'

$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

foreach ($entry in Import-Csv -Path $InventoryPath) {
    try {
        $server = Connect-DbaInstance -SqlInstance $entry.SqlInstance -SqlCredential $cred -ConnectTimeout $ConnectTimeout
    }
    catch {
        Write-Warning -Message "$($entry.Name) ($($entry.SqlInstance)) is unreachable: $($_.Exception.Message)"
        continue
    }
    foreach ($database in Get-DbaDatabase -SqlInstance $server -ExcludeSystem) {
        # SMO writes 1/1/0001 for a backup that never happened.
        $lastFull = if ($database.LastFullBackup -eq [datetime]::MinValue) { $null } else { $database.LastFullBackup }
        [pscustomobject]@{
            Instance         = $entry.Name
            Database         = $database.Name
            LastFullBackup   = $lastFull
            RecoveryModel    = $database.RecoveryModel.ToString()
            SizeMB           = [math]::Round($database.SizeMB, 2)
            LogBackupMissing = $database.RecoveryModel -eq 'Full' -and $database.LastLogBackup -eq [datetime]::MinValue
        }
    }
}
