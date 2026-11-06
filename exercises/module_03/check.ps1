<#
.SYNOPSIS
Checks the exercise of module 3.

.DESCRIPTION
Runs database-summary.ps1 and instance-card.ps1 from the root of the clone, recomputes the
expected objects from lab/backups/sql1 and from data/instances.csv, and compares them,
property by property, types included. Exits with 0 when both parts are right, 1 otherwise,
and says what is missing. With -Solution, checks the files of the solution folder.

.EXAMPLE
./exercises/module_03/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your files.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$root = Resolve-Path (Join-Path $PSScriptRoot '..' '..')
$problems = [System.Collections.Generic.List[string]]::new()

function Invoke-Answer ([string] $Name) {
    $path = Join-Path $folder $Name
    Push-Location $root
    try { $output = @(& $path) }
    catch { $problems.Add("${Name}: it stops with an error: $($_.Exception.Message)"); return $null }
    finally { Pop-Location }
    if ($output.Count -eq 0) { $problems.Add("${Name}: it returns no object yet."); return $null }
    if ($output | Where-Object { $_.GetType().FullName -like 'Microsoft.PowerShell.Commands.Internal.Format.*' }) {
        $problems.Add("${Name}: it returns formatting objects. Remove the Format-* command at the end: the check needs the objects.")
        return $null
    }
    , $output
}

# Part 1: one object per database of sql1, from the backup files.
$backups = Join-Path $root 'lab' 'backups' 'sql1'
if (-not (Test-Path -Path $backups)) {
    if ($Solution) { & (Join-Path $root 'setup' 'new-backupfiles.ps1') | Out-Null }
    else { $problems.Add('lab/backups/sql1 does not exist: run ./setup/new-backupfiles.ps1 first.') }
}
if (Test-Path -Path $backups) {
    $expected = @(Get-ChildItem -Path $backups -Recurse -File -Filter sql1_* | Group-Object -Property { $_.Directory.Parent.Name })
    $summary = Invoke-Answer 'database-summary.ps1'
    if ($null -ne $summary) {
        $before = $problems.Count
        foreach ($property in 'Database', 'FileCount', 'SizeMB', 'LastBackup') {
            if ($null -eq $summary[0].PSObject.Properties[$property]) { $problems.Add("database-summary.ps1: no $property property.") }
        }
        if ($problems.Count -eq $before) {
            if ($summary.Count -ne $expected.Count) { $problems.Add("database-summary.ps1: $($summary.Count) object(s), but sql1 has $($expected.Count) databases.") }
            foreach ($group in $expected) {
                $answer = @($summary | Where-Object -FilterScript { $_.Database -eq $group.Name })
                if ($answer.Count -ne 1) { $problems.Add("database-summary.ps1: $($answer.Count) object(s) for the database $($group.Name), expected 1."); continue }
                $answer = $answer[0]
                if ($answer.FileCount -ne $group.Count) { $problems.Add("database-summary.ps1: $($group.Name) has FileCount $($answer.FileCount); expected $($group.Count).") }
                $mb = ($group.Group | Measure-Object -Property Length -Sum).Sum / 1MB
                if ([math]::Abs([double]$answer.SizeMB - $mb) -gt 0.06) { $problems.Add("database-summary.ps1: $($group.Name) has SizeMB $($answer.SizeMB); expected $([math]::Round($mb, 1)).") }
                $last = ($group.Group | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
                if ($answer.LastBackup -isnot [datetime]) {
                    $type = if ($null -eq $answer.LastBackup) { 'null' } else { $answer.LastBackup.GetType().Name }
                    $problems.Add("database-summary.ps1: LastBackup of $($group.Name) is a $type, not a [datetime].")
                }
                elseif ([math]::Abs(($answer.LastBackup - $last).TotalSeconds) -gt 1) { $problems.Add("database-summary.ps1: LastBackup of $($group.Name) is $($answer.LastBackup); expected $last.") }
            }
        }
    }
}

# Part 2: the card of compta01, an object with five properties in order.
$row = Import-Csv -Path (Join-Path $root 'data' 'instances.csv') | Where-Object -Property Name -eq -Value 'compta01'
$card = Invoke-Answer 'instance-card.ps1'
if ($null -ne $card) {
    $names = 'Name', 'SqlInstance', 'Port', 'Environment', 'Owner'
    if ($card.Count -ne 1) { $problems.Add("instance-card.ps1: $($card.Count) object(s) instead of 1.") }
    elseif ($card[0] -is [System.Collections.IDictionary]) { $problems.Add('instance-card.ps1: it returns a hash table, not an object. Cast it with [pscustomobject].') }
    else {
        $card = $card[0]
        $actual = @($card.PSObject.Properties.Name)
        if (($actual -join ',') -ne ($names -join ',')) { $problems.Add("instance-card.ps1: properties $($actual -join ', '); expected $($names -join ', '), in this order.") }
        else {
            foreach ($property in 'Name', 'SqlInstance', 'Environment', 'Owner') {
                if ($card.$property -ne $row.$property) { $problems.Add("instance-card.ps1: $property is '$($card.$property)'; expected '$($row.$property)'.") }
            }
            if ($card.Port -isnot [int]) {
                $type = if ($null -eq $card.Port) { 'null' } else { $card.Port.GetType().Name }
                $problems.Add("instance-card.ps1: Port is a $type, not an [int].")
            }
            elseif ($card.Port -ne [int]($row.SqlInstance -split ',')[1]) { $problems.Add("instance-card.ps1: Port is $($card.Port); expected $(($row.SqlInstance -split ',')[1]).") }
        }
    }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object { "FAIL  $_" }
    exit 1
}
'OK    module 3: the summary per database and the card of compta01 are right.'
exit 0
