<#
.SYNOPSIS
Checks the exercise of module 9.

.DESCRIPTION
Reads the secret sql-lab in the vault PachaOps, then runs Get-UnderfilledSession.ps1 in a
child pwsh -NoProfile -NonInteractive, as a scheduler would, for two dates: 2 November 2026
and 5 October 2026. Each time, the CSV file it writes must be separated by semicolons and
hold exactly the sessions that a control query returns, with the same number of enrollments.
The script must not contain the lab password.
Exits with 0 when everything is right, 1 otherwise, and says what is missing. With
-Solution, checks the file of the solution folder.

.EXAMPLE
./exercises/module_09/check.ps1
#>
[CmdletBinding()]
param(
    # Check the solution instead of your file.
    [switch] $Solution
)
$ErrorActionPreference = 'Stop'
$folder = if ($Solution) { Join-Path $PSScriptRoot 'solution' } else { $PSScriptRoot }
$script = Join-Path $folder 'Get-UnderfilledSession.ps1'
$name = 'Get-UnderfilledSession.ps1'
$pwsh = [System.Environment]::ProcessPath
$problems = [System.Collections.Generic.List[string]]::new()

$syntaxErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref] $null, [ref] $syntaxErrors)
if ($syntaxErrors) {
    "FAIL  ${name}: PowerShell cannot read it, line $($syntaxErrors[0].Extent.StartLineNumber): $($syntaxErrors[0].Message)"
    exit 1
}

$cred = try { Get-Secret -Name sql-lab -Vault PachaOps -WarningAction SilentlyContinue } catch { $null }
if ($cred -isnot [pscredential]) {
    'FAIL  the secret sql-lab cannot be read in the vault PachaOps: create it as in clip 9.1, or run ./demos/module_09/00-setup.ps1.'
    exit 1
}
if ((Get-Content -Path $script -Raw).Contains($cred.GetNetworkCredential().Password)) {
    $problems.Add("${name} contains the lab password: read it in the vault, with Get-Secret.")
}

Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$control = @'
SELECT s.SessionId, COUNT(en.EnrollmentId) AS Enrolled, MAX(r.Seats) AS Seats
FROM Course.Session AS s
JOIN Reference.TrainingRoom AS r ON r.TrainingRoomId = s.TrainingRoomId
LEFT JOIN Enrollment.Enrollment AS en ON en.SessionId = s.SessionId AND en.CancellationDate IS NULL
WHERE s.StartDate BETWEEN @From AND DATEADD(day, 29, @From)
  AND s.StatusCode <> 'CANCELED'
GROUP BY s.SessionId
HAVING COUNT(en.EnrollmentId) < MAX(r.Seats) / 2.0;
'@

$work = Join-Path ([System.IO.Path]::GetTempPath()) "m09-check-$([guid]::NewGuid())"
New-Item -Path $work -ItemType Directory | Out-Null
try {
    foreach ($day in '2026-11-02', '2026-10-05') {
        $csv = Join-Path $work "underfilled-$day.csv"
        $output = & $pwsh -NoProfile -NonInteractive -File $script -From $day -Path $csv 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errorText = ($output | Where-Object -FilterScript { $_ -is [System.Management.Automation.ErrorRecord] } | Select-Object -First 1 | Out-String).Trim()
            $problems.Add("${name} -From ${day}: exit code $LASTEXITCODE, expected 0. $errorText")
            continue
        }
        if (-not (Test-Path -Path $csv) -or (Get-Item -Path $csv).Length -eq 0) {
            $problems.Add("${name} -From ${day}: no CSV file written to -Path, or an empty one.")
            continue
        }
        $header = Get-Content -Path $csv -TotalCount 1
        if (-not $header.Contains(';')) {
            $problems.Add("${name} -From ${day}: the CSV file is not separated by semicolons: $header")
            continue
        }
        $rows = @(Import-Csv -Path $csv -Delimiter ';')
        foreach ($column in 'SessionId', 'Course', 'StartDate', 'Seats', 'Enrolled') {
            if ($rows.Count -gt 0 -and $null -eq $rows[0].PSObject.Properties[$column]) {
                $problems.Add("${name} -From ${day}: the column $column is missing.")
            }
        }
        $expected = @(Invoke-DbaQuery -SqlInstance 'localhost,14533' -SqlCredential $cred -Database PachadataTraining `
            -Query $control -SqlParameter @{ From = [datetime] $day } -As PSObject -EnableException)
        $found = @{}
        foreach ($row in $rows) { $found[[string] $row.SessionId] = [string] $row.Enrolled }
        $missing = @($expected | Where-Object -FilterScript { -not $found.ContainsKey([string] $_.SessionId) })
        $wanted = @{}
        foreach ($row in $expected) { $wanted[[string] $row.SessionId] = [string] $row.Enrolled }
        $extra = @($rows | Where-Object -FilterScript { -not $wanted.ContainsKey([string] $_.SessionId) })
        $wrong = @($expected | Where-Object -FilterScript {
            $found.ContainsKey([string] $_.SessionId) -and $found[[string] $_.SessionId] -ne [string] $_.Enrolled })
        if ($missing.Count -gt 0) {
            $problems.Add("${name} -From ${day}: $($missing.Count) session(s) missing out of $($expected.Count), such as $($missing[0].SessionId).")
        }
        if ($extra.Count -gt 0) {
            $problems.Add("${name} -From ${day}: $($extra.Count) session(s) too many, such as $($extra[0].SessionId).")
        }
        if ($wrong.Count -gt 0) {
            $problems.Add("${name} -From ${day}: $($wrong.Count) session(s) with a wrong Enrolled count, such as $($wrong[0].SessionId).")
        }
    }
}
finally { Remove-Item -Path $work -Recurse -Force }

if ($problems.Count -gt 0) {
    $problems | ForEach-Object -Process { "FAIL  $_" }
    exit 1
}
'OK    module 9: Get-UnderfilledSession.ps1 writes the sessions less than half full, separated by semicolons.'
exit 0
