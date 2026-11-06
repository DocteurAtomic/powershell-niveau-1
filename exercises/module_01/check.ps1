<#
.SYNOPSIS
Checks the exercise of module 1.

.DESCRIPTION
Reads answers.ps1 and checks that every command is written with its full name and named
parameters, then runs it from the root of the clone and checks what it returns: first the
current date and time (a DateTime), then the absolute path of data/instances.csv (a
PathInfo or a string). Exits with 0 when both are right, 1 otherwise, and says what is
missing. With -Solution, checks the file of the solution folder.

.EXAMPLE
./exercises/module_01/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your file.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$path = Join-Path $folder 'answers.ps1'
$root = (Resolve-Path -Path (Join-Path $PSScriptRoot '..' '..')).Path
$problems = [System.Collections.Generic.List[string]]::new()

function Exit-Check {
    $problems | ForEach-Object { "FAIL  $_" }
    exit 1
}

# 1. How the commands are written: read from the file, not run.
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref] $tokens, [ref] $errors)
if ($errors.Count -gt 0) {
    $problems.Add("answers.ps1: PowerShell cannot read line $($errors[0].Extent.StartLineNumber): $($errors[0].Message)")
    Exit-Check
}
$commands = @($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true))
if ($commands.Count -eq 0) {
    $problems.Add('answers.ps1: it contains no command yet.')
    Exit-Check
}
foreach ($command in $commands) {
    $name = $command.GetCommandName()
    $line = $command.Extent.StartLineNumber
    if (-not $name) { $problems.Add("answers.ps1, line ${line}: the command name is not written as a plain name."); continue }
    $info = Get-Command -Name $name -ErrorAction SilentlyContinue
    if (-not $info) { $problems.Add("answers.ps1, line ${line}: PowerShell knows no command named '$name'."); continue }
    if ($info.CommandType -eq 'Alias') { $problems.Add("answers.ps1, line ${line}: '$name' is an alias of $($info.Definition); write the full name."); continue }
    if ($info.CommandType -eq 'Application') { $problems.Add("answers.ps1, line ${line}: '$name' is the program $($info.Source) of the system, not a PowerShell command: it returns text."); continue }
    $previous = $command.CommandElements[0]
    foreach ($element in ($command.CommandElements | Select-Object -Skip 1)) {
        $isParameter = $element -is [System.Management.Automation.Language.CommandParameterAst]
        $previousWaits = $previous -is [System.Management.Automation.Language.CommandParameterAst] -and $null -eq $previous.Argument
        if (-not $isParameter -and -not $previousWaits) {
            $problems.Add("answers.ps1, line ${line}: the value $($element.Extent.Text) of $name has no parameter name before it.")
        }
        $previous = $element
    }
}
if ($problems.Count -gt 0) { Exit-Check }

# 2. What the commands return, run from the root of the clone.
Push-Location -Path $root
try { $output = @(& $path) }
catch { $problems.Add("answers.ps1: it stops with an error: $($_.Exception.Message)"); Exit-Check }
finally { Pop-Location }

if ($output.Count -ne 2) {
    $problems.Add("answers.ps1: it returns $($output.Count) object(s); expected 2, the date first, then the path.")
    Exit-Check
}
$date, $resolved = $output
if ($date -isnot [datetime] -and $resolved -is [datetime]) {
    $problems.Add('answers.ps1: the date comes second; write the date first, then the path.')
    Exit-Check
}
if ($date -is [string]) {
    $problems.Add('answers.ps1: the first object is a String, not a DateTime. A -Format parameter turns the date into text: remove it.')
}
elseif ($date -isnot [datetime]) {
    $problems.Add("answers.ps1: the first object is a $($date.GetType().Name), not a DateTime.")
}
elseif ([math]::Abs(((Get-Date) - $date).TotalMinutes) -gt 5) {
    $problems.Add("answers.ps1: the first object is $date, not the current date and time.")
}
$expected = [System.IO.Path]::GetFullPath((Join-Path $root 'data' 'instances.csv'))
$text = if ($resolved -is [System.Management.Automation.PathInfo]) { $resolved.Path } elseif ($resolved -is [string]) { $resolved } else { $null }
if ($null -eq $text) {
    $problems.Add("answers.ps1: the second object is a $($resolved.GetType().Name), not a path (PathInfo or String).")
}
elseif (-not [System.IO.Path]::IsPathRooted($text) -or [System.IO.Path]::GetFullPath($text) -ne $expected) {
    $problems.Add("answers.ps1: the second object is '$text'; expected the absolute path '$expected'.")
}

if ($problems.Count -gt 0) { Exit-Check }
'OK    module 1: the current date and the absolute path of data/instances.csv are right.'
exit 0
