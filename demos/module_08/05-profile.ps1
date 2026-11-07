# Module 8, clip 8.5: the profile, and a script that must not depend on it. Typed one command
# at a time, from the root of the clone, after 04-install-module.ps1. A profile is created
# only if you have none, and removed at the end; an existing profile is never touched.

$PROFILE
$PROFILE | Select-Object -Property *
$hadProfile = Test-Path -Path $PROFILE
$hadProfile

# A profile that sets the path of the backup share, created only when there is none.
if (-not $hadProfile) { $null = New-Item -ItemType File -Path $PROFILE -Force -Value '$BackupShare = ''lab/backups''' }
Get-Content -Path $PROFILE
pwsh -Command '(Get-ChildItem -Path $BackupShare -Recurse -File).Count'
pwsh -NoProfile -Command '(Get-ChildItem -Path $BackupShare -Recurse -File).Count'
if (-not $hadProfile) { Remove-Item -Path $PROFILE }

# The answer to the team: the retention, in a new process, without any profile.
pwsh -NoProfile -File demos/module_08/retention-job.ps1 -ReferenceDate 2026-11-02 -WhatIf
