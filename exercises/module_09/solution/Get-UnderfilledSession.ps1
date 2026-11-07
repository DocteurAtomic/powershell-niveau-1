<#
.SYNOPSIS
Lists the sessions of the next 30 days that are less than half full, in a CSV file.

.DESCRIPTION
Solution of the exercise of module 9. For the sessions that start on From or in the 29 days
after it, that are not canceled, and whose number of enrollments that are not canceled is
less than half the seats of their training room, writes one line per session in Path: a CSV
file separated by semicolons, with the columns SessionId, Course, StartDate, Seats and
Enrolled.

The login of the lab is read in the vault PachaOps, secret sql-lab (clip 9.1). The date is
passed to the query as a parameter, never pasted into its text.

.EXAMPLE
./exercises/module_09/solution/Get-UnderfilledSession.ps1 -From 2026-11-02 -Path lab/underfilled.csv
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

$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

$query = @'
SELECT s.SessionId,
       c.Code AS Course,
       s.StartDate,
       r.Seats,
       e.Enrolled
FROM Course.Session AS s
JOIN Course.Course AS c ON c.CourseId = s.CourseId
JOIN Reference.TrainingRoom AS r ON r.TrainingRoomId = s.TrainingRoomId
CROSS APPLY (SELECT COUNT(*) AS Enrolled
             FROM Enrollment.Enrollment AS en
             WHERE en.SessionId = s.SessionId
               AND en.CancellationDate IS NULL) AS e
WHERE s.StartDate >= @From
  AND s.StartDate < DATEADD(day, 30, @From)
  AND s.StatusCode <> 'CANCELED'
  AND e.Enrolled * 2 < r.Seats
ORDER BY s.StartDate, s.SessionId;
'@
$sessions = Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $cred -Database PachadataTraining `
    -Query $query -SqlParameter @{ From = $From.Date } -As PSObject

$sessions |
    Select-Object -Property SessionId, Course,
        @{ Name = 'StartDate'; Expression = { $_.StartDate.ToString('yyyy-MM-dd') } },
        Seats, Enrolled |
    Export-Csv -Path $Path -Delimiter ';'
