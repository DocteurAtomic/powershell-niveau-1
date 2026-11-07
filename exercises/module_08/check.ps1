<#
.SYNOPSIS
Checks the exercise of module 8.

.DESCRIPTION
Reads the manifest of PachaOps with Test-ModuleManifest, copies the folder of the module to
lab/check-module-08/modules/PachaOps/0.1.0, imports it from that copy, and checks its
version and its exported functions. Then tries the functions on backup files of known ages
that it creates under lab/check-module-08/backups: Get-BackupAge, Get-OldBackup,
Get-BackupSummary, and Remove-OldBackup with -WhatIf (nothing may disappear), then without.
Removes its files at the end. Exits with 0 when the module is right, 1 otherwise, and says
what is missing. With -Solution, checks the module of the solution folder.

.EXAMPLE
./exercises/module_08/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your module.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$source = if ($Solution) { Join-Path $PSScriptRoot 'solution' 'PachaOps' } else { Join-Path $PSScriptRoot 'PachaOps' }
$root = Resolve-Path (Join-Path $PSScriptRoot '..' '..')
$work = Join-Path $root 'lab' 'check-module-08'
$problems = [System.Collections.Generic.List[string]]::new()
$expectedFunctions = 'Get-BackupAge', 'Get-BackupSummary', 'Get-OldBackup', 'Remove-OldBackup'

function Test-Manifest {
    $path = Join-Path $source 'PachaOps.psd1'
    if (-not (Test-Path -Path $path)) {
        $problems.Add("$path does not exist: write it with New-ModuleManifest, next to PachaOps.psm1.")
        return
    }
    try { $manifest = Test-ModuleManifest -Path $path -ErrorAction Stop }
    catch { $problems.Add("Test-ModuleManifest refuses PachaOps.psd1: $($_.Exception.Message)"); return }
    $data = Import-PowerShellDataFile -Path $path
    if ($data.RootModule -ne 'PachaOps.psm1') { $problems.Add("RootModule is '$($data.RootModule)'; expected 'PachaOps.psm1'.") }
    if ([string]$manifest.Version -ne '0.1.0') { $problems.Add("ModuleVersion is $($manifest.Version); expected 0.1.0.") }
    if ([string]::IsNullOrWhiteSpace($data.Author)) { $problems.Add('The manifest has no Author.') }
    if ([string]::IsNullOrWhiteSpace($data.Description)) { $problems.Add('The manifest has no Description.') }
    $listed = @($data.FunctionsToExport)
    if ($listed.Count -eq 0) { $problems.Add('FunctionsToExport is missing or empty: list the four functions.') }
    elseif ($listed | Where-Object -FilterScript { $_ -match '[*?]' }) { $problems.Add("FunctionsToExport contains a wildcard ($($listed -join ', ')): list the four functions by name.") }
}

function Test-Module {
    # The module is imported from a copy in another folder, laid out as in a module folder.
    $copy = Join-Path $work 'modules' 'PachaOps' '0.1.0'
    $null = New-Item -ItemType Directory -Path $copy -Force
    Copy-Item -Path (Join-Path $source '*') -Destination $copy -Recurse
    try { $module = Import-Module -Name (Join-Path $copy 'PachaOps.psd1') -Force -PassThru -ErrorAction Stop }
    catch { $problems.Add("PachaOps does not import from another folder: $($_.Exception.Message) Does PachaOps.psm1 load a file by a path outside its own folder?"); return }
    try {
        $exported = @($module.ExportedFunctions.Keys | Sort-Object)
        $missing = @($expectedFunctions | Where-Object -FilterScript { $_ -notin $exported })
        $extra = @($exported | Where-Object -FilterScript { $_ -notin $expectedFunctions })
        if ($missing.Count -gt 0) { $problems.Add("PachaOps does not export $($missing -join ', ').") }
        if ($extra.Count -gt 0) { $problems.Add("PachaOps exports functions that are not asked for: $($extra -join ', ').") }
        if ($missing.Count -gt 0) { return }
        Test-Function
    }
    finally {
        Remove-Module -Name PachaOps -Force -ErrorAction SilentlyContinue
    }
}

function Test-Function {
    # Backup files of known ages, written at 8 AM on 2 November 2026 minus 3, 20 and 40 days,
    # and a README that the retention must never remove.
    $reference = Get-Date -Date '2026-11-02 08:00'
    $share = Join-Path $work 'backups'
    $files = [ordered]@{
        'sql1/Sales/FULL/sql1_Sales_FULL_new.bak'  = 3
        'sql1/Sales/DIFF/sql1_Sales_DIFF_mid.bak'  = 20
        'sql1/Sales/LOG/sql1_Sales_LOG_old.trn'    = 40
        'sql1/Sales/FULL/README.txt'               = 40
    }
    foreach ($name in $files.Keys) {
        $path = Join-Path $share $name
        $null = New-Item -ItemType Directory -Path (Split-Path -Path $path) -Force
        Set-Content -Path $path -Value 'backup'
        (Get-Item -Path $path).LastWriteTime = $reference.AddDays(-$files[$name])
    }
    $backups = Get-ChildItem -Path $share -Recurse -File -Include *.bak, *.trn | Sort-Object -Property Name

    $aged = @($backups | PachaOps\Get-BackupAge -ReferenceDate $reference)
    if ($aged.Count -ne 3) { $problems.Add("Get-BackupAge returns $($aged.Count) object(s) for 3 files sent through the pipeline.") }
    foreach ($item in $aged) {
        $want = $files[($item.FullName.Substring($share.Length + 1) -replace '\\', '/')]
        if ($null -eq $item.PSObject.Properties['AgeDays']) { $problems.Add("Get-BackupAge: $($item.Name) has no AgeDays property."); continue }
        if ([math]::Abs([double]$item.AgeDays - $want) -gt 0.01) { $problems.Add("Get-BackupAge: $($item.Name) has AgeDays $($item.AgeDays); expected $want.") }
    }

    $old = @(PachaOps\Get-OldBackup -Path $share -RetentionDays 28 -ReferenceDate $reference)
    if ($old.Count -ne 1 -or $old[0].Name -ne 'sql1_Sales_LOG_old.trn') {
        $problems.Add("Get-OldBackup -RetentionDays 28 returns $($old.Count) file(s) ($($old.Name -join ', ')); expected sql1_Sales_LOG_old.trn only.")
    }

    $summary = @(PachaOps\Get-BackupSummary -Name sql1 -Root $share)
    if ($summary.Count -ne 1 -or $summary[0].FileCount -ne 3) {
        $problems.Add("Get-BackupSummary -Name sql1 returns FileCount $($summary.FileCount); expected 3 backup files.")
    }

    $null = PachaOps\Remove-OldBackup -Path $share -RetentionDays 10 -ReferenceDate $reference -WhatIf
    $left = @(Get-ChildItem -Path $share -Recurse -File).Count
    if ($left -ne 4) { $problems.Add("Remove-OldBackup -WhatIf removed $(4 - $left) file(s): with -WhatIf, nothing may be removed."); return }

    $removed = @(PachaOps\Remove-OldBackup -Path $share -RetentionDays 10 -ReferenceDate $reference -Confirm:$false)
    $remaining = @(Get-ChildItem -Path $share -Recurse -File | ForEach-Object -Process { $_.Name } | Sort-Object)
    if (($remaining -join ',') -ne 'README.txt,sql1_Sales_FULL_new.bak') {
        $problems.Add("After Remove-OldBackup -RetentionDays 10, the share holds $($remaining -join ', '); expected README.txt and sql1_Sales_FULL_new.bak.")
    }
    if ($removed.Count -ne 2) { $problems.Add("Remove-OldBackup returns $($removed.Count) object(s); expected the 2 files it removed.") }
}

if (-not (Test-Path -Path (Join-Path $source 'PachaOps.psm1'))) { $problems.Add("$source/PachaOps.psm1 does not exist.") }
else {
    Test-Manifest
    if ($problems.Count -eq 0) {
        try { Test-Module }
        finally { Remove-Item -Path $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object -Process { "FAIL  $_" }
    exit 1
}
'OK    module 8: PachaOps 0.1.0 imports from another folder, exports its four functions, and -WhatIf removes nothing.'
exit 0
