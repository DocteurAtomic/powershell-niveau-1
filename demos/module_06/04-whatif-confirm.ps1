# ci: skip. It asks for confirmations (-Confirm): the video answers Y, then N.
# Module 6, clip 6.4: -WhatIf and -Confirm. Typed one command at a time at the console, from
# the root of the clone, with the backup files created for 2 November 2026.

# A simple function takes -WhatIf without complaint, and removes for real.
$null = New-Item -ItemType Directory -Path lab/draft -Force
Set-Content -Path lab/draft/notes.txt -Value 'draft'
function Clear-Draft {
    param()
    Remove-Item -Path lab/draft -Recurse
}
Clear-Draft -WhatIf
Test-Path -Path lab/draft

# An advanced function refuses it, unless it declares SupportsShouldProcess.
$null = New-Item -ItemType Directory -Path lab/draft -Force
Set-Content -Path lab/draft/notes.txt -Value 'draft'
function Clear-Draft {
    [CmdletBinding()]
    param()
    Remove-Item -Path lab/draft -Recurse
}
Clear-Draft -WhatIf
function Clear-Draft {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Remove-Item -Path lab/draft -Recurse
}
Clear-Draft -WhatIf
Test-Path -Path lab/draft
Remove-Item -Path lab/draft -Recurse

# The retention, on one database first.
. ./demos/module_06/backup-functions.ps1
Remove-OldBackup -Path lab/backups/sql1/DBA -RetentionDays 28 -ReferenceDate 2026-11-02 -WhatIf
Remove-OldBackup -Path lab/backups/sql1/DBA -RetentionDays 28 -ReferenceDate 2026-11-02 -Confirm
$ConfirmPreference

# The confirmation removed one file: create the backup files again before the whole share.
./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02
