<#
.SYNOPSIS
Counts, in each error log of a folder, the lines that match a pattern.

.DESCRIPTION
Solution of the exercise of module 7. Stops with an error, and an exit code of 1 when run by
pwsh -File, when the folder does not exist or when one of its files is not a SQL Server
error log, whose first line starts with a date and a time. Every file is checked before the
first object is returned, so the output is never half a summary. Otherwise returns one
object per file: the name of the file, the pattern, the number of matching lines, and the
date and time of the last matching line ($null when no line matches).

.EXAMPLE
./exercises/module_07/solution/Get-ErrorlogSummary.ps1 -Path data/errorlog -Pattern 'Login failed'
#>
[CmdletBinding()]
param(
    # The folder of the error logs.
    [Parameter(Mandatory)]
    [string] $Path,

    # The text to look for, a regular expression as for Select-String.
    [Parameter(Mandatory)]
    [string] $Pattern
)

$ErrorActionPreference = 'Stop'
$datePattern = '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{2})'

if (-not (Test-Path -Path $Path -PathType Container)) {
    throw "The folder '$Path' does not exist."
}
$files = @(Get-ChildItem -Path $Path -File)
foreach ($file in $files) {
    $firstLine = Get-Content -Path $file.FullName -TotalCount 1
    if ($firstLine -notmatch $datePattern) {
        throw "The file '$($file.Name)' is not a SQL Server error log: its first line does not start with a date."
    }
}
Write-Verbose -Message "$($files.Count) error logs under $Path."

foreach ($file in $files) {
    $found = @(Select-String -Path $file.FullName -Pattern $Pattern)
    $lastMatch = $null
    if ($found.Count -gt 0 -and $found[-1].Line -match $datePattern) {
        $lastMatch = [datetime]$Matches[1]
    }
    [pscustomobject]@{
        File       = $file.Name
        Pattern    = $Pattern
        MatchCount = $found.Count
        LastMatch  = $lastMatch
    }
}
