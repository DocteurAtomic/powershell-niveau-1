# ci: skip. Do not copy: this script shows that -WhatIf does not reach a function of a
# script module. Run with -WhatIf, it really removes the files. See retention-job.ps1.
<#
.SYNOPSIS
The nightly retention of the backup share, with the PachaBackup module. Unsafe version.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $Path = 'lab/backups',
    [int] $RetentionDays = 28,
    [datetime] $ReferenceDate = (Get-Date)
)
Import-Module -Name PachaBackup -RequiredVersion 0.1.0
$removed = Remove-OldBackup -Path $Path -RetentionDays $RetentionDays -ReferenceDate $ReferenceDate
"$(@($removed).Count) backup files removed"
