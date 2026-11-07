<#
.SYNOPSIS
Counts, in each error log of a folder, the lines that match a pattern.

.DESCRIPTION
Exercise of module 5. Returns one object per file of the folder, with four properties:
File, Pattern, MatchCount and LastMatch (see the README of the exercise).

.EXAMPLE
./exercises/module_05/Get-ErrorlogSummary.ps1 -Path data/errorlog -Pattern 'Login failed'
#>
param(
    # TODO: a mandatory [string] parameter Path, the folder of the error logs.
    # TODO: a mandatory [string] parameter Pattern, the text to look for.
)

# TODO: one object per file of the folder.
