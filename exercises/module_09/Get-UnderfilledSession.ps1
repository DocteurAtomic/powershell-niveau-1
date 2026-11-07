<#
.SYNOPSIS
Lists the sessions of the next 30 days that are less than half full, in a CSV file.

.DESCRIPTION
Exercise of module 9. For the sessions that start on From or in the 29 days after it, that
are not canceled, and whose number of enrollments that are not canceled is less than half
the seats of their training room, writes one line per session in Path: a CSV file separated
by semicolons, with the columns SessionId, Course, StartDate, Seats and Enrolled.

The login of the lab is read in the vault PachaOps, secret sql-lab (clip 9.1). The date is
passed to the query as a parameter, never pasted into its text.

.EXAMPLE
./exercises/module_09/Get-UnderfilledSession.ps1 -From 2026-11-02 -Path lab/underfilled.csv
#>
[CmdletBinding()]
param(
    # The first day of the 30 days to look at.
    [Parameter(Mandatory)]
    [datetime] $From,

    # The CSV file to write.
    [Parameter(Mandatory)]
    [string] $Path,

    # The instance that holds PachadataTraining.
    [string] $SqlInstance = 'localhost,14533'
)
$ErrorActionPreference = 'Stop'

# 1. Read the credential in the vault.
# 2. Write the query: Course.Session, Course.Course (Code), Reference.TrainingRoom (Seats),
#    Enrollment.Enrollment (CancellationDate IS NULL), with @From as a parameter.
# 3. Run it with Invoke-DbaQuery and -SqlParameter.
# 4. Export the rows to $Path, separated by semicolons.
