<#
.SYNOPSIS
Checks the exercise of module 2.

.DESCRIPTION
Runs top-files.ps1 and extensions.ps1, recomputes the expected answer from the files of
$PSHOME, and compares the objects. Exits with 0 when both parts are right, 1 otherwise,
and says what is missing. With -Solution, checks the files of the solution folder.

.EXAMPLE
./exercises/module_02/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your files.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$problems = [System.Collections.Generic.List[string]]::new()
$files = Get-ChildItem -Path $PSHOME -File

function Invoke-Answer ([string] $Name) {
    $path = Join-Path $folder $Name
    try { $output = @(& $path) }
    catch { $problems.Add("${Name}: it stops with an error: $($_.Exception.Message)"); return $null }
    if ($output.Count -eq 0) { $problems.Add("${Name}: it returns no object yet."); return $null }
    if ($output | Where-Object { $_.GetType().FullName -like 'Microsoft.PowerShell.Commands.Internal.Format.*' }) {
        $problems.Add("${Name}: it returns formatting objects. Remove the Format-* command at the end: the check needs the objects.")
        return $null
    }
    , $output
}

# Part 1: the five largest files, largest first, with Name and SizeKB.
$expected = @($files | Sort-Object -Property Length -Descending | Select-Object -First 5)
$top = Invoke-Answer 'top-files.ps1'
if ($null -ne $top) {
    if ($top.Count -ne 5) { $problems.Add("top-files.ps1: $($top.Count) object(s) instead of 5.") }
    foreach ($property in 'Name', 'SizeKB') {
        if ($null -eq $top[0].PSObject.Properties[$property]) { $problems.Add("top-files.ps1: no $property property.") }
    }
    if ($problems.Count -eq 0) {
        for ($i = 0; $i -lt 5; $i++) {
            $file = $files | Where-Object -Property Name -eq -Value $top[$i].Name
            if (-not $file) { $problems.Add("top-files.ps1: object $($i + 1) is named '$($top[$i].Name)', which is not a file of `$PSHOME."); continue }
            if ($file.Length -ne $expected[$i].Length) {
                $problems.Add("top-files.ps1: object $($i + 1) is '$($top[$i].Name)' ($($file.Length) bytes); expected '$($expected[$i].Name)' ($($expected[$i].Length) bytes). Sorted largest first?")
            }
            $kb = $file.Length / 1KB
            if ([math]::Abs([double]$top[$i].SizeKB - $kb) -gt 1) {
                $problems.Add("top-files.ps1: SizeKB of '$($top[$i].Name)' is $($top[$i].SizeKB); expected about $([math]::Round($kb)).")
            }
        }
    }
}

# Part 2: the number of files per extension, most frequent first.
$groups = @($files | Group-Object -Property Extension)
$counts = Invoke-Answer 'extensions.ps1'
if ($null -ne $counts) {
    $before = $problems.Count
    foreach ($property in 'Name', 'Count') {
        if ($null -eq $counts[0].PSObject.Properties[$property]) { $problems.Add("extensions.ps1: no $property property.") }
    }
    if ($problems.Count -eq $before) {
        if ($counts.Count -ne $groups.Count) { $problems.Add("extensions.ps1: $($counts.Count) object(s), but `$PSHOME has $($groups.Count) extensions.") }
        foreach ($group in $groups) {
            $answer = $counts | Where-Object -FilterScript { $_.Name -eq $group.Name }
            $label = if ($group.Name) { $group.Name } else { '(no extension)' }
            if (-not $answer) { $problems.Add("extensions.ps1: no object for $label.") }
            elseif ($answer.Count -ne $group.Count) { $problems.Add("extensions.ps1: $label has Count $($answer.Count); expected $($group.Count).") }
        }
        for ($i = 1; $i -lt $counts.Count; $i++) {
            if ($counts[$i].Count -gt $counts[$i - 1].Count) { $problems.Add('extensions.ps1: not sorted, the most frequent extension first.'); break }
        }
    }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object { "FAIL  $_" }
    exit 1
}
'OK    module 2: the five largest files and the count per extension are right.'
exit 0
