<#
.SYNOPSIS
Writes one message in each output stream. Module 7, clip 7.4.

.EXAMPLE
./demos/module_07/05-streams.ps1 -Verbose -InformationAction Continue
#>
[CmdletBinding()]
param()

Write-Output -InputObject 'Output: an object for the pipeline (1)'
Write-Error -Message 'Error: a database folder cannot be read (2)'
Write-Warning -Message 'Warning: a backup file is empty (3)'
Write-Verbose -Message 'Verbose: reading lab/backups/sql1 (4)'
Write-Information -MessageData 'Information: report written for 2 November (6)'
