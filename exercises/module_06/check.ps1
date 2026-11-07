<#
.SYNOPSIS
Checks the exercise of module 6.

.DESCRIPTION
Loads Get-BackupAge.ps1 by dot-sourcing, creates three backup files of known ages under
lab/check-module-06, sends them to Get-BackupAge through the pipeline, and checks the number
of objects returned and the AgeDays property of each. Removes the files at the end. Exits
with 0 when the function is right, 1 otherwise, and says what is missing. With -Solution,
checks the file of the solution folder.

.EXAMPLE
./exercises/module_06/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your file.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$root = Resolve-Path (Join-Path $PSScriptRoot '..' '..')
$problems = [System.Collections.Generic.List[string]]::new()

function Test-Answer {
    $command = Get-Command -Name Get-BackupAge -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $command) { $problems.Add('Get-BackupAge.ps1 does not define a function Get-BackupAge.'); return }
    if (-not $command.CmdletBinding) { $problems.Add('Get-BackupAge is not an advanced function: add [CmdletBinding()] before param().') }
    foreach ($name in 'File', 'ReferenceDate') {
        if (-not $command.Parameters.ContainsKey($name)) { $problems.Add("Get-BackupAge has no -$name parameter.") }
    }
    if ($problems.Count -gt 0) { return }
    $byValue = $command.Parameters['File'].Attributes |
        Where-Object -FilterScript { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipeline }
    if ($null -eq $byValue) { $problems.Add('The -File parameter does not accept the pipeline: add ValueFromPipeline to its [Parameter()].'); return }

    # Three files of known ages, written at 8 AM on 2 November 2026 minus 1, 7.5 and 30 days.
    $reference = Get-Date -Date '2026-11-02 08:00'
    $fixture = Join-Path $root 'lab' 'check-module-06'
    $null = New-Item -ItemType Directory -Path $fixture -Force
    try {
        $expected = [ordered]@{ 'a_FULL.bak' = 1; 'b_DIFF.bak' = 7.5; 'c_LOG.trn' = 30 }
        foreach ($name in $expected.Keys) {
            $path = Join-Path $fixture $name
            Set-Content -Path $path -Value 'backup'
            (Get-Item -Path $path).LastWriteTime = $reference.AddDays(-$expected[$name])
        }
        $files = Get-ChildItem -Path $fixture -File | Sort-Object -Property Name
        try { $output = @($files | Get-BackupAge -ReferenceDate $reference) }
        catch { $problems.Add("Get-BackupAge stops with an error: $($_.Exception.Message)"); return }
        if ($output.Count -eq 0) { $problems.Add('Get-BackupAge returns no object yet.'); return }
        if ($output.Count -ne $files.Count) {
            $hint = if ($output.Count -eq 1) { ' Only the last file came out: is the body of the function in a process block?' } else { '' }
            $problems.Add("Get-BackupAge returns $($output.Count) object(s) for $($files.Count) files.$hint")
            return
        }
        foreach ($item in $output) {
            if ($null -eq $item.PSObject.Properties['Name'] -or -not $expected.Contains([string]$item.Name)) {
                $problems.Add('Get-BackupAge must return the files it receives, with their Name: one object does not have the name of a file sent.')
                continue
            }
            if ($null -eq $item.PSObject.Properties['AgeDays']) { $problems.Add("$($item.Name): no AgeDays property."); continue }
            $want = $expected[[string]$item.Name]
            if ([math]::Abs([double]$item.AgeDays - $want) -gt 0.01) { $problems.Add("$($item.Name): AgeDays is $($item.AgeDays); expected $want.") }
        }
        # Without -ReferenceDate, the age is computed from now.
        $recent = Join-Path $fixture 'd_FULL.bak'
        Set-Content -Path $recent -Value 'backup'
        (Get-Item -Path $recent).LastWriteTime = (Get-Date).AddDays(-2)
        $now = @(Get-Item -Path $recent | Get-BackupAge)
        if ($now.Count -ne 1 -or [math]::Abs([double]$now[0].AgeDays - 2) -gt 0.01) {
            $problems.Add("Without -ReferenceDate, a file written 2 days ago has AgeDays $($now[0].AgeDays); expected 2: is the default value of -ReferenceDate now?")
        }
        # The parameter can also be named.
        $named = @(Get-BackupAge -File (Get-Item -Path $recent) -ReferenceDate (Get-Date))
        if ($named.Count -ne 1) { $problems.Add("Get-BackupAge -File <one file> returns $($named.Count) object(s); expected 1.") }
    }
    finally {
        Remove-Item -Path $fixture -Recurse -Force
    }
}

$file = Join-Path $folder 'Get-BackupAge.ps1'
if (-not (Test-Path -Path $file)) { $problems.Add("$file does not exist.") }
else {
    try { . $file } catch { $problems.Add("Get-BackupAge.ps1 stops with an error when loaded: $($_.Exception.Message)") }
    if ($problems.Count -eq 0) { Test-Answer }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object { "FAIL  $_" }
    exit 1
}
'OK    module 6: Get-BackupAge takes the files from the pipeline and adds their age to each.'
exit 0
