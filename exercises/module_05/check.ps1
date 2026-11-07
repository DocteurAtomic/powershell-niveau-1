<#
.SYNOPSIS
Checks the exercise of module 5.

.DESCRIPTION
Reads the parameters of Get-ErrorlogSummary.ps1, then runs it on data/errorlog with two
patterns, and on a copy of two of the three files, and compares each object it returns with
the values recomputed from the files: one object per file, MatchCount, and LastMatch as a
[datetime] or $null. Exits with 0 when everything is right, 1 otherwise, and says what is
missing. With -Solution, checks the file of the solution folder.

.EXAMPLE
./exercises/module_05/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your file.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$script = Join-Path $folder 'Get-ErrorlogSummary.ps1'
$root = Resolve-Path (Join-Path $PSScriptRoot '..' '..')
$logs = Join-Path $root 'data' 'errorlog'
$problems = [System.Collections.Generic.List[string]]::new()
$name = 'Get-ErrorlogSummary.ps1'

# The interface: two mandatory parameters, Path and Pattern.
$syntaxErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref] $null, [ref] $syntaxErrors)
if ($syntaxErrors) {
    "FAIL  ${name}: PowerShell cannot read it, line $($syntaxErrors[0].Extent.StartLineNumber): $($syntaxErrors[0].Message)"
    exit 1
}
$parameters = (Get-Command -Name $script).Parameters
foreach ($parameter in 'Path', 'Pattern') {
    if (-not $parameters.ContainsKey($parameter)) { $problems.Add("${name}: no $parameter parameter."); continue }
    $mandatory = $parameters[$parameter].Attributes |
        Where-Object -FilterScript { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
    if (-not $mandatory) { $problems.Add("${name}: the $parameter parameter is not mandatory.") }
}

# What the script should return, recomputed from the files.
function Get-Expected ([string] $Folder, [string] $Pattern) {
    foreach ($file in Get-ChildItem -Path $Folder -File) {
        $found = @(Select-String -Path $file.FullName -Pattern $Pattern)
        $last = $null
        if ($found.Count -gt 0) { $last = [datetime]::ParseExact($found[-1].Line.Substring(0, 22), 'yyyy-MM-dd HH:mm:ss.ff', $null) }
        [pscustomobject]@{ File = $file.Name; MatchCount = $found.Count; LastMatch = $last }
    }
}

function Test-Run ([string] $Folder, [string] $Pattern, [string] $Label) {
    $expected = @(Get-Expected -Folder $Folder -Pattern $Pattern)
    try { $output = @(& $script -Path $Folder -Pattern $Pattern) }
    catch { $problems.Add("$Label it stops with an error: $($_.Exception.Message)"); return }
    if ($output.Count -eq 0) { $problems.Add("$Label it returns no object yet."); return }
    if ($output | Where-Object -FilterScript { $_.GetType().FullName -like 'Microsoft.PowerShell.Commands.Internal.Format.*' }) {
        $problems.Add("$Label it returns formatting objects. Remove the Format-* command: the check needs the objects."); return
    }
    if ($output | Where-Object -FilterScript { $_ -is [string] }) {
        $problems.Add("$Label it returns text. Return one [pscustomobject] per file, not strings."); return
    }
    foreach ($property in 'File', 'Pattern', 'MatchCount', 'LastMatch') {
        if ($null -eq $output[0].PSObject.Properties[$property]) { $problems.Add("$Label no $property property."); return }
    }
    if ($output.Count -ne $expected.Count) { $problems.Add("$Label $($output.Count) object(s), but the folder has $($expected.Count) files.") }
    foreach ($file in $expected) {
        $answer = @($output | Where-Object -FilterScript { $_.File -eq $file.File })
        if ($answer.Count -ne 1) { $problems.Add("$Label $($answer.Count) object(s) for the file $($file.File), expected 1. File is the name of the file, without its folder."); continue }
        $answer = $answer[0]
        if ($answer.Pattern -ne $Pattern) { $problems.Add("$Label $($file.File) has Pattern '$($answer.Pattern)'; expected '$Pattern'.") }
        if ($answer.MatchCount -isnot [int]) {
            $type = if ($null -eq $answer.MatchCount) { 'null' } else { $answer.MatchCount.GetType().Name }
            $problems.Add("$Label MatchCount of $($file.File) is a $type, not an [int].")
        }
        elseif ($answer.MatchCount -ne $file.MatchCount) { $problems.Add("$Label $($file.File) has MatchCount $($answer.MatchCount); expected $($file.MatchCount).") }
        if ($null -eq $file.LastMatch) {
            if ($null -ne $answer.LastMatch) { $problems.Add("$Label $($file.File) has no matching line: LastMatch should be `$null, not '$($answer.LastMatch)'.") }
        }
        elseif ($answer.LastMatch -isnot [datetime]) {
            $type = if ($null -eq $answer.LastMatch) { 'null' } else { $answer.LastMatch.GetType().Name }
            $problems.Add("$Label LastMatch of $($file.File) is a $type, not a [datetime].")
        }
        elseif ([math]::Abs(($answer.LastMatch - $file.LastMatch).TotalSeconds) -gt 0.5) {
            $problems.Add("$Label $($file.File) has LastMatch $($answer.LastMatch.ToString('yyyy-MM-dd HH:mm:ss.ff')); expected $($file.LastMatch.ToString('yyyy-MM-dd HH:mm:ss.ff')).")
        }
    }
}

if ($problems.Count -eq 0) {
    Test-Run -Folder $logs -Pattern 'Login failed' -Label "${name} -Pattern 'Login failed':"
    Test-Run -Folder $logs -Pattern 'finance_report' -Label "${name} -Pattern 'finance_report':"
    # A folder of two files only, somewhere else: the script must use its Path parameter.
    $copy = Join-Path ([System.IO.Path]::GetTempPath()) "m05-check-$([guid]::NewGuid())"
    New-Item -Path $copy -ItemType Directory | Out-Null
    try {
        Copy-Item -Path (Join-Path $logs 'errorlog.2'), (Join-Path $logs 'errorlog.3') -Destination $copy
        Test-Run -Folder $copy -Pattern 'Login failed' -Label "${name} on a folder of two files:"
    }
    finally { Remove-Item -Path $copy -Recurse -Force }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object -Process { "FAIL  $_" }
    exit 1
}
'OK    module 5: Get-ErrorlogSummary.ps1 returns the right object for each file.'
exit 0
