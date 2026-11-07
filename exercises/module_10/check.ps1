<#
.SYNOPSIS
Checks the exercise of module 10.

.DESCRIPTION
Reads the secret sql-lab in the vault PachaOps and checks that the database Finance of
./demos/module_10/00-setup.ps1 exists on sql2. Creates on sql2 a database m10_check in the
full recovery model, backed up in full and in log, then runs Get-DatabaseInventory.ps1 on an
inventory of three instances: sql1, sql2 and one name that does not resolve.

Each object must have RecoveryModel (a string), SizeMB (a number) and LogBackupMissing (a
boolean). Finance must be flagged (full recovery model, no log backup); PachadataTraining
(simple recovery model) and m10_check (a log backup exists) must not. SizeMB must match the
size of the database within 1 MB. The script must not contain the lab password.
Removes m10_check, its history and its backup files at the end.
Exits with 0 when everything is right, 1 otherwise, and says what is missing. With
-Solution, checks the file of the solution folder.

.EXAMPLE
./exercises/module_10/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your file.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$script = Join-Path $folder 'Get-DatabaseInventory.ps1'
$name = 'Get-DatabaseInventory.ps1'
$problems = [System.Collections.Generic.List[string]]::new()
$sql1 = 'localhost,14533'
$sql2 = 'localhost,14534'

$syntaxErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref] $null, [ref] $syntaxErrors)
if ($syntaxErrors) {
    "FAIL  ${name}: PowerShell cannot read it, line $($syntaxErrors[0].Extent.StartLineNumber): $($syntaxErrors[0].Message)"
    exit 1
}

$cred = try { Get-Secret -Name sql-lab -Vault PachaOps -WarningAction SilentlyContinue } catch { $null }
if ($cred -isnot [pscredential]) {
    'FAIL  the secret sql-lab cannot be read in the vault PachaOps: create it as in clip 9.1, or run ./demos/module_09/00-setup.ps1.'
    exit 1
}
if ((Get-Content -Path $script -Raw).Contains($cred.GetNetworkCredential().Password)) {
    $problems.Add("${name} contains the lab password: read it in the vault, with Get-Secret.")
}

Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sizes = @{}
foreach ($database in Get-DbaDatabase -SqlInstance $sql1, $sql2 -SqlCredential $cred -ExcludeSystem -EnableException) {
    $sizes["$($database.SqlInstance)/$($database.Name)"] = $database.SizeMB
}
if (-not $sizes.ContainsKey('sql2/Finance')) {
    'FAIL  the database Finance is missing on sql2 (localhost,14534): run ./demos/module_10/00-setup.ps1.'
    exit 1
}

# A database in full recovery with a log backup: it must not be flagged.
$files = '/var/opt/mssql/backup/m10_check_full.bak', '/var/opt/mssql/backup/m10_check_log.trn'
$cleanup = @'
IF DB_ID(N'm10_check') IS NOT NULL
BEGIN
    ALTER DATABASE m10_check SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE m10_check;
END;
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'm10_check';
EXEC master.sys.xp_delete_files @full;
EXEC master.sys.xp_delete_files @log;
'@
$work = Join-Path ([System.IO.Path]::GetTempPath()) "m10-check-$([guid]::NewGuid())"
New-Item -Path $work -ItemType Directory | Out-Null
try {
    $setup = @'
CREATE DATABASE m10_check;
ALTER DATABASE m10_check SET RECOVERY FULL;
'@
    Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Query $setup -EnableException
    Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Query 'BACKUP DATABASE m10_check TO DISK = @full;' `
        -SqlParameter @{ full = $files[0] } -EnableException
    Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Query 'BACKUP LOG m10_check TO DISK = @log;' `
        -SqlParameter @{ log = $files[1] } -EnableException
    $sizes['sql2/m10_check'] = (Get-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database m10_check -EnableException).SizeMB

    $inventory = Join-Path $work 'instances.csv'
    @(
        [pscustomobject]@{ Name = 'sql1'; SqlInstance = $sql1; Environment = 'Production' }
        [pscustomobject]@{ Name = 'sql2'; SqlInstance = $sql2; Environment = 'Production' }
        [pscustomobject]@{ Name = 'nowhere01'; SqlInstance = 'nowhere01.pachadata.example,1433'; Environment = 'Test' }
    ) | Export-Csv -Path $inventory

    $rows = try {
        @(& $script -InventoryPath $inventory -ConnectTimeout 3 -WarningAction SilentlyContinue)
    }
    catch {
        "FAIL  ${name} stopped: $($_.Exception.Message)"
        exit 1
    }

    $expected = @(
        @{ Instance = 'sql2'; Database = 'Finance'; RecoveryModel = 'Full'; LogBackupMissing = $true }
        @{ Instance = 'sql1'; Database = 'PachadataTraining'; RecoveryModel = 'Simple'; LogBackupMissing = $false }
        @{ Instance = 'sql2'; Database = 'm10_check'; RecoveryModel = 'Full'; LogBackupMissing = $false }
    )
    foreach ($want in $expected) {
        $label = "$($want.Instance)/$($want.Database)"
        $row = $rows | Where-Object -FilterScript { $_.Instance -eq $want.Instance -and $_.Database -eq $want.Database } | Select-Object -First 1
        if ($null -eq $row) {
            $problems.Add("${name}: no object for the database $label.")
            continue
        }
        foreach ($property in 'RecoveryModel', 'SizeMB', 'LogBackupMissing') {
            if ($null -eq $row.PSObject.Properties[$property]) {
                $problems.Add("${name}: the property $property is missing on $label.")
            }
        }
        if ($null -eq $row.PSObject.Properties['LogBackupMissing']) { continue }
        if ([string] $row.RecoveryModel -ne $want.RecoveryModel) {
            $problems.Add("${name}: RecoveryModel of $label is '$($row.RecoveryModel)', expected '$($want.RecoveryModel)'.")
        }
        if ($row.RecoveryModel -isnot [string]) {
            $problems.Add("${name}: RecoveryModel of $label is a $($row.RecoveryModel.GetType().FullName), expected a string (ToString()).")
        }
        if ($row.SizeMB -isnot [double] -and $row.SizeMB -isnot [decimal] -and $row.SizeMB -isnot [int]) {
            $problems.Add("${name}: SizeMB of $label is not a number.")
        }
        elseif ([math]::Abs($row.SizeMB - $sizes[$label]) -gt 1) {
            $problems.Add("${name}: SizeMB of $label is $($row.SizeMB), expected about $([math]::Round($sizes[$label], 2)).")
        }
        if ($row.LogBackupMissing -isnot [bool]) {
            $problems.Add("${name}: LogBackupMissing of $label is not a boolean (`$true or `$false).")
        }
        elseif ($row.LogBackupMissing -ne $want.LogBackupMissing) {
            $problems.Add("${name}: LogBackupMissing of $label is $($row.LogBackupMissing), expected $($want.LogBackupMissing).")
        }
    }
}
finally {
    Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $cred -Query $cleanup `
        -SqlParameter @{ full = $files[0]; log = $files[1] } -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    Remove-Item -Path $work -Recurse -Force
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object -Process { "FAIL  $_" }
    exit 1
}
'OK    module 10: Get-DatabaseInventory.ps1 flags Finance, and neither PachadataTraining nor a database with a log backup.'
exit 0
