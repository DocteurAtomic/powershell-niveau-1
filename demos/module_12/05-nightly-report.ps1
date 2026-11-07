<#
.SYNOPSIS
Runs the morning inventory of module 10 the way a scheduler runs it, and writes one line of trace.

.DESCRIPTION
The answer to the second half of the request of module 12: the report of module 10, every
night, without anybody at the console. A scheduler (cron, a systemd timer, the Task
Scheduler of Windows) starts this script with
pwsh -NoProfile -NonInteractive -File <full path of this script>, in the home folder of the
account, with no console and nobody to answer a question.

The script moves to the root of the clone, so that the relative paths of the report find
their files, runs ./demos/module_10/05-morning-inventory.ps1 (which reads the sql-lab
secret of the PachaOps vault), and appends one line to -TracePath: when the run started and
ended, its exit code, what the report found, the PowerShell that ran it and the account. It
ends with the exit code it wrote: 0 when the report was written, 1 when it stopped.

The trace is what tells, the next morning, that the scheduled run happened and how it ended:
nobody saw its screen.

.PARAMETER TracePath
The CSV file of the trace, one line per run. By default lab/nightly-report.csv in the clone.

.PARAMETER ReportPath
The HTML page of the report. By default lab/morning-inventory.html in the clone.

.EXAMPLE
pwsh -NoProfile -NonInteractive -File ./demos/module_12/05-nightly-report.ps1

.EXAMPLE
Import-Csv -Path lab/nightly-report.csv | Select-Object -Last 1
#>
[CmdletBinding()]
param(
    [string] $TracePath,
    [string] $ReportPath
)
$ErrorActionPreference = 'Stop'

# A scheduler starts the script in the home folder: work from the root of the clone.
$root = (Resolve-Path -Path (Join-Path $PSScriptRoot '..' '..')).Path
Set-Location -Path $root
if (-not $TracePath) { $TracePath = Join-Path $root 'lab' 'nightly-report.csv' }
if (-not $ReportPath) { $ReportPath = Join-Path $root 'lab' 'morning-inventory.html' }
New-Item -ItemType Directory -Path (Split-Path -Path $TracePath -Parent), (Split-Path -Path $ReportPath -Parent) -Force | Out-Null

$start = Get-Date
$exitCode = 0
$summary = $null
$message = ''
try {
    $report = Join-Path $root 'demos' 'module_10' '05-morning-inventory.ps1'
    $summary = & $report -InventoryPath (Join-Path $root 'data' 'instances.csv') -Path $ReportPath -WarningAction SilentlyContinue
}
catch {
    $exitCode = 1
    $message = $_.Exception.Message
}

[pscustomobject]@{
    Start       = $start.ToString('yyyy-MM-dd HH:mm:ss')
    End         = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    ExitCode    = $exitCode
    Instances   = $summary.Instances
    Unreachable = $summary.Unreachable
    ToCheck     = $summary.ToCheck
    Report      = $ReportPath
    PowerShell  = $PSVersionTable.PSVersion.ToString()
    Pwsh        = [System.Environment]::ProcessPath
    User        = [System.Environment]::UserName
    Message     = $message
} | Export-Csv -Path $TracePath -Append -Encoding utf8

exit $exitCode
