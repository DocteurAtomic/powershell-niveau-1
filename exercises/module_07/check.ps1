<#
.SYNOPSIS
Checks the exercise of module 7.

.DESCRIPTION
Runs Get-ErrorlogSummary.ps1 three times. On data/errorlog, it must return one object per
file, without error. On a folder that does not exist, and on a copy of two error logs next
to data/instances.csv, it is run by pwsh -NoProfile -NonInteractive -File, as a scheduler
would run it: it must exit with 1, and the error it writes on stderr must name the folder, then the
file.
Exits with 0 when everything is right, 1 otherwise, and says what is missing. With
-Solution, checks the file of the solution folder.

.EXAMPLE
./exercises/module_07/check.ps1
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
$pwsh = [System.Environment]::ProcessPath
$problems = [System.Collections.Generic.List[string]]::new()
$name = 'Get-ErrorlogSummary.ps1'

$syntaxErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref] $null, [ref] $syntaxErrors)
if ($syntaxErrors) {
    "FAIL  ${name}: PowerShell cannot read it, line $($syntaxErrors[0].Extent.StartLineNumber): $($syntaxErrors[0].Message)"
    exit 1
}

# Runs the script in a child pwsh, as a scheduler does, and returns its exit code and what
# it wrote on its error output (stderr), where PowerShell writes the errors.
function Invoke-Child ([string] $Folder) {
    $lines = & $pwsh -NoProfile -NonInteractive -File $script -Path $Folder -Pattern 'Login failed' 2>&1
    $code = $LASTEXITCODE
    $errors = $lines | Where-Object -FilterScript { $_ -is [System.Management.Automation.ErrorRecord] } | Out-String
    [pscustomobject]@{ ExitCode = $code; Text = $errors }
}

# The error may be wrapped over several lines on the screen: compare without blanks.
function Test-Named ([string] $Text, [string] $Word) {
    $flat = $Text -replace '[\s|]', ''
    $flat.Contains($Word)
}

# 1. The error logs of the course: one object per file, no error.
$expected = @(Get-ChildItem -Path $logs -File).Count
try {
    $output = @(& $script -Path $logs -Pattern 'Login failed')
    $objects = @($output | Where-Object -FilterScript { $null -ne $_.PSObject.Properties['MatchCount'] })
    if ($objects.Count -ne $expected) {
        $problems.Add("${name} on data/errorlog: $($objects.Count) object(s) with a MatchCount, expected $expected, one per file.")
    }
}
catch {
    $problems.Add("${name} on data/errorlog: it stops with an error, but every file there is an error log: $($_.Exception.Message)")
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) "m07-check-$([guid]::NewGuid())"
New-Item -Path $work -ItemType Directory | Out-Null
try {
    # 2. A folder that does not exist.
    $missing = Join-Path $work 'errorlog-gone'
    $run = Invoke-Child -Folder $missing
    if ($run.ExitCode -ne 1) {
        $problems.Add("${name} on a folder that does not exist: exit code $($run.ExitCode), expected 1.")
    }
    if (-not (Test-Named -Text $run.Text -Word 'errorlog-gone')) {
        $problems.Add("${name} on a folder that does not exist: the error does not name the folder, errorlog-gone.")
    }

    # 3. A folder where a CSV file sits next to two error logs.
    $mixed = Join-Path $work 'errorlog-mixed'
    New-Item -Path $mixed -ItemType Directory | Out-Null
    Copy-Item -Path (Join-Path $logs 'errorlog.1'), (Join-Path $logs 'errorlog.2') -Destination $mixed
    Copy-Item -Path (Join-Path $root 'data' 'instances.csv') -Destination $mixed
    $run = Invoke-Child -Folder $mixed
    if ($run.ExitCode -ne 1) {
        $problems.Add("${name} on a folder that holds instances.csv: exit code $($run.ExitCode), expected 1.")
    }
    if (-not (Test-Named -Text $run.Text -Word 'instances.csv')) {
        $problems.Add("${name} on a folder that holds instances.csv: the error does not name the file, instances.csv.")
    }
}
finally { Remove-Item -Path $work -Recurse -Force }

if ($problems.Count -gt 0) {
    $problems | ForEach-Object -Process { "FAIL  $_" }
    exit 1
}
'OK    module 7: Get-ErrorlogSummary.ps1 stops, names the folder or the file, and exits with 1.'
exit 0
