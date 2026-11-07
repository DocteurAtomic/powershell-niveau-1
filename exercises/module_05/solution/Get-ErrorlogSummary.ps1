<#
.SYNOPSIS
Counts, in each error log of a folder, the lines that match a pattern.

.DESCRIPTION
Solution of the exercise of module 5. Returns one object per file of the folder: the name
of the file, the pattern, the number of matching lines, and the date and time of the last
matching line, read at the start of the line ($null when no line matches).

.EXAMPLE
./exercises/module_05/solution/Get-ErrorlogSummary.ps1 -Path data/errorlog -Pattern 'Login failed'
#>
param(
    # The folder of the error logs.
    [Parameter(Mandatory)]
    [string] $Path,

    # The text to look for, a regular expression as for Select-String.
    [Parameter(Mandatory)]
    [string] $Pattern
)

foreach ($file in Get-ChildItem -Path $Path -File) {
    $found = @(Select-String -Path $file.FullName -Pattern $Pattern)
    $lastMatch = $null
    if ($found.Count -gt 0 -and $found[-1].Line -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{2})') {
        $lastMatch = [datetime]$Matches[1]
    }
    [pscustomobject]@{
        File       = $file.Name
        Pattern    = $Pattern
        MatchCount = $found.Count
        LastMatch  = $lastMatch
    }
}
