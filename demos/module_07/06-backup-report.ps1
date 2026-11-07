# ci: skip. Path is mandatory; 07-morning-report.ps1 runs this script with its parameters.

<#
.SYNOPSIS
Reports the last backup of each database of one instance, and stops when the folder is wrong.

.DESCRIPTION
The morning report of module 5, made to fail loudly. It stops with an error that names the
folder, and an exit code of 1, when the folder does not exist or has no database folder, so
an empty report can no longer pass for a report with nothing to say. Otherwise it returns one
object per database folder: the last backup file that is not empty, its type, its age in
hours, the number of empty backup files, and a status (Missing, Late, Empty file or OK).
With -Verbose, it says which folder it reads. Module 7 of the course.

.EXAMPLE
./demos/module_07/06-backup-report.ps1 -Path lab/backups/sql1 -Verbose

.EXAMPLE
pwsh -NoProfile -File ./demos/module_07/06-backup-report.ps1 -Path lab/backups/sql9
#>
[CmdletBinding()]
param(
    # The folder of one instance on the backup share, such as lab/backups/sql1.
    [Parameter(Mandatory)]
    [string] $Path,

    # The age, in hours, beyond which the last backup of a database is late.
    [int] $MaxAgeHours = 24,

    # The moment the report is written for; now by default.
    [datetime] $ReferenceDate = (Get-Date),

    # Return only the databases whose status is not OK.
    [switch] $IssuesOnly
)

# Any error stops the script: no half-written report.
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $Path -PathType Container)) {
    throw "The backup folder '$Path' does not exist. No report is written."
}
$databases = @(Get-ChildItem -Path $Path -Directory)
if ($databases.Count -eq 0) {
    throw "The backup folder '$Path' has no database folder. No report is written."
}
Write-Verbose -Message "Reading $($databases.Count) database folders under $Path."

foreach ($database in $databases) {
    $files = Get-ChildItem -Path $database.FullName -Recurse -File -Include *.bak, *.trn
    $last = $files |
        Where-Object -Property Length -GT -Value 0 |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1
    $emptyFiles = @($files | Where-Object -Property Length -EQ -Value 0).Count

    $type = switch -Wildcard ($last.Name) {
        '*_FULL_*' { 'FULL' }
        '*_DIFF_*' { 'DIFF' }
        '*.trn'    { 'LOG' }
    }
    $ageHours = $null
    if ($null -ne $last) {
        $ageHours = [int]($ReferenceDate - $last.LastWriteTime).TotalHours
    }

    $status = if ($null -eq $last) {
        'Missing'
    } elseif ($ageHours -gt $MaxAgeHours) {
        'Late'
    } elseif ($emptyFiles -gt 0) {
        'Empty file'
    } else {
        'OK'
    }

    if ($IssuesOnly -and $status -eq 'OK') { continue }

    [pscustomobject]@{
        Database   = $database.Name
        LastBackup = $last.LastWriteTime
        Type       = $type
        AgeHours   = $ageHours
        EmptyFiles = $emptyFiles
        Status     = $status
    }
}
