# Module 7, clip 7.3: native programs, $LASTEXITCODE, $? and exit.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# git, a native program: it answers with an exit code, not with an error. $? tells about
# the last command only, so read it right after.
git log --max-count 1 --format=%s
$LASTEXITCODE
git log --max-count 1 --format=%s module-99-end
$?
$?
$LASTEXITCODE
$Error.Count

# A child pwsh is a native program too: the report of module 5 exits with 0 on a missing folder.
pwsh -NoProfile -File ./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql9 2> $null
$LASTEXITCODE
pwsh -NoProfile -File ./demos/module_07/03-test-share.ps1 -Path lab/backups/sql9 2> $null
$LASTEXITCODE

# The same script, run in the console: exit ends the script, not the console.
./demos/module_07/03-test-share.ps1 -Path lab/backups/sql9
$LASTEXITCODE

# $PSNativeCommandUseErrorActionPreference: a non-zero exit code becomes an error.
$PSNativeCommandUseErrorActionPreference = $true
git log --max-count 1 --format=%s module-99-end
'The console goes on'
try {
    $ErrorActionPreference = 'Stop'
    git log --max-count 1 --format=%s module-99-end
    'Never written'
} catch {
    "Caught: $($_.Exception.Message)"
}
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false
