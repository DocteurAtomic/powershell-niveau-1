# ci: skip. Removes the old backup files of lab/backups; 04-install-module.ps1 and
# 05-profile.ps1 run it with -WhatIf.
<#
.SYNOPSIS
The nightly retention of the backup share, with the PachaBackup module.

.DESCRIPTION
Removes the backup files older than the retention, with Remove-OldBackup of the module
PachaBackup 0.1.0, and says how many it removed. -WhatIf is passed on to Remove-OldBackup
explicitly: a function of a script module does not see the -WhatIf of the script.

.EXAMPLE
./demos/module_08/retention-job.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # The backup share, searched recursively.
    [string] $Path = 'lab/backups',
    # Files written more than this number of days before the reference date are removed.
    [int] $RetentionDays = 28,
    # The moment the retention is computed from; now by default.
    [datetime] $ReferenceDate = (Get-Date)
)
Import-Module -Name PachaBackup -RequiredVersion 0.1.0
$removed = Remove-OldBackup -Path $Path -RetentionDays $RetentionDays -ReferenceDate $ReferenceDate -WhatIf:$WhatIfPreference
"$(@($removed).Count) backup files removed"
