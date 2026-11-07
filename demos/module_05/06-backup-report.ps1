# ci: skip. Path is mandatory; 08-morning-report.ps1 runs this script with its parameters.

<#
.SYNOPSIS
Reports the last backup of each database of one instance, and its age.

.DESCRIPTION
Reads the backup files of one instance on the backup share, in the layout of Ola
Hallengren's Maintenance Solution (<database>/FULL, DIFF and LOG folders), and returns one
object per database folder: the last backup file that is not empty, its type, its age in
hours, the number of empty backup files, and a status. The status is Missing when the
folder has no backup file, Late when the last backup is older than MaxAgeHours, Empty file
when a backup file has 0 bytes, and OK otherwise. Module 5 of the course.

.EXAMPLE
./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql1

.EXAMPLE
./demos/module_05/06-backup-report.ps1 -Path lab/backups/sql1 -MaxAgeHours 168 -IssuesOnly
#>
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

foreach ($database in Get-ChildItem -Path $Path -Directory) {
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
