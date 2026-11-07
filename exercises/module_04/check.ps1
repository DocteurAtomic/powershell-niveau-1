<#
.SYNOPSIS
Checks the exercise of module 4.

.DESCRIPTION
Deletes lab/production-owners.json, runs production-owners.ps1 from the root of the clone,
reads the JSON file it writes, and compares it with the production instances of
data/instances.csv, grouped by owner: one object per owner, with the right instances.
Exits with 0 when the file is right, 1 otherwise, and says what is missing. An owner whose
Instances is a string instead of an array is accepted, with a note. With -Solution, checks
the file of the solution folder.

.EXAMPLE
./exercises/module_04/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your file.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$root = Resolve-Path (Join-Path $PSScriptRoot '..' '..')
$json = Join-Path $root 'lab' 'production-owners.json'
$problems = [System.Collections.Generic.List[string]]::new()
$notes = [System.Collections.Generic.List[string]]::new()

New-Item -ItemType Directory -Path (Join-Path $root 'lab') -Force | Out-Null
if (Test-Path -Path $json) { Remove-Item -Path $json }

Push-Location $root
try { & (Join-Path $folder 'production-owners.ps1') | Out-Null }
catch { $problems.Add("production-owners.ps1: it stops with an error: $($_.Exception.Message)") }
finally { Pop-Location }

$expected = Import-Csv -Path (Join-Path $root 'data' 'instances.csv') |
    Where-Object -Property Environment -eq -Value Production |
    Group-Object -Property Owner

if ($problems.Count -eq 0) {
    if (-not (Test-Path -Path $json)) { $problems.Add('lab/production-owners.json does not exist: the script writes nothing yet.') }
    else {
        $text = Get-Content -Path $json -Raw
        $answer = $null
        try { $answer = @($text | ConvertFrom-Json) }
        catch { $problems.Add("lab/production-owners.json is not valid JSON: $($_.Exception.Message)") }
        if ($null -ne $answer) {
            $missing = @('Owner', 'Instances' | Where-Object -FilterScript { $null -eq $answer[0].PSObject.Properties[$_] })
            if ($missing.Count -gt 0) {
                $found = $answer[0].PSObject.Properties.Name -join ', '
                $problems.Add("lab/production-owners.json: no $($missing -join ' or ') property, only $found. Select Owner and Instances from the groups with calculated properties.")
            }
            else {
                if ($answer.Count -ne $expected.Count) { $problems.Add("lab/production-owners.json: $($answer.Count) object(s), but the production instances have $($expected.Count) owners.") }
                foreach ($group in $expected) {
                    $entry = @($answer | Where-Object -FilterScript { $_.Owner -eq $group.Name })
                    if ($entry.Count -ne 1) { $problems.Add("lab/production-owners.json: $($entry.Count) object(s) for the owner $($group.Name), expected 1."); continue }
                    $instances = $entry[0].Instances
                    if ($instances -is [string]) { $notes.Add("Instances of $($group.Name) is a string, not an array: see the last question of the README.") }
                    $actual = @($instances | ForEach-Object -Process { "$_" } | Sort-Object)
                    $wanted = @($group.Group.Name | Sort-Object)
                    if (($actual -join ', ') -ne ($wanted -join ', ')) {
                        $problems.Add("lab/production-owners.json: $($group.Name) has the instances '$($actual -join ', ')'; expected '$($wanted -join ', ')'.")
                    }
                }
            }
        }
    }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object -Process { "FAIL  $_" }
    exit 1
}
$notes | ForEach-Object -Process { "NOTE  $_" }
'OK    module 4: lab/production-owners.json has one object per owner of production instances, with the right instances.'
exit 0
