# Module 7, clip 7.2: try, catch, finally, and throw.
# Run from the root of the clone, one command at a time at the console. The video uses
# backup files created for 2 November 2026:
#   ./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# An error that does not stop: catch never sees it.
try { Get-Item -Path lab/backups/sql1/Payroll } catch { "Caught: $($_.Exception.Message)" }

# The same error, made to stop: catch receives it.
try { Get-Item -Path lab/backups/sql1/Payroll -ErrorAction Stop } catch { "Caught: $($_.Exception.Message)" }

# In catch, $_ is the ErrorRecord.
try {
    Get-Item -Path lab/backups/sql1/Payroll -ErrorAction Stop
} catch {
    $_.GetType().FullName
    $_.Exception.GetType().FullName
    $_.TargetObject
}

# One catch per type of exception, the most precise first.
foreach ($stamp in '20261101', '2026110') {
    try {
        [datetime]::ParseExact($stamp, 'yyyyMMdd', $null)
    } catch [System.FormatException] {
        "Not a date: $stamp"
    } catch {
        "Something else: $($_.Exception.Message)"
    }
}

# finally runs in every case: here, it removes the lock of the report.
try {
    New-Item -Path lab/report.lock -ItemType File | Out-Null
    'Report started'
    Get-Item -Path lab/backups/sql1/Payroll -ErrorAction Stop
    'Report written'
} catch {
    "Report failed: $($_.Exception.Message)"
} finally {
    Remove-Item -Path lab/report.lock
    'Lock removed'
}
Test-Path -Path lab/report.lock

# throw raises your own error, with your own message.
$Path = 'lab/backups/sql9'
try {
    if (-not (Test-Path -Path $Path -PathType Container)) {
        throw "The backup folder '$Path' does not exist."
    }
} catch {
    $_.Exception.GetType().FullName
    $_.Exception.Message
}
