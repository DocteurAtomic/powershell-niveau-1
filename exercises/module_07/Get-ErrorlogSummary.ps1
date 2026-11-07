<#
.SYNOPSIS
Counts, in each error log of a folder, the lines that match a pattern.

.DESCRIPTION
Exercise of module 7. This is the solution of module 5: it returns one object per file of
the folder, with File, Pattern, MatchCount and LastMatch. Make it stop with an error and an
exit code of 1 when the folder does not exist, or when a file of the folder is not a SQL
Server error log (see the README of the exercise).

.EXAMPLE
./exercises/module_07/Get-ErrorlogSummary.ps1 -Path data/errorlog -Pattern 'Login failed'
#>
param(
    # The folder of the error logs.
    [Parameter(Mandatory)]
    [string] $Path,

    # The text to look for, a regular expression as for Select-String.
    [Parameter(Mandatory)]
    [string] $Pattern
)

# TODO: stop, with a message that names the folder, when $Path is not a folder.
# TODO: stop, with a message that names the file, when a file is not an error log.

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
