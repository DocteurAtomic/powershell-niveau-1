<#
.SYNOPSIS
Tells whether a folder of the backup share exists, by its exit code.

.DESCRIPTION
Returns the folder and exits with 0 when it exists; writes an error and exits with 1 when it
does not. A scheduler or another script reads the exit code. Module 7, clip 7.3.

.EXAMPLE
./demos/module_07/03-test-share.ps1 -Path lab/backups/sql9
#>
param(
    # The folder of one instance on the backup share.
    [string] $Path = (Join-Path -Path $PSScriptRoot -ChildPath '../../lab/backups/sql1')
)

if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error -Message "The backup folder '$Path' does not exist."
    exit 1
}
Get-Item -Path $Path
exit 0
