# Module 12, clip 12.4: what comes next.
# Run from the root of the clone, one command at a time at the console, after clips 12.1 to
# 12.3: the planning application on sql2, and the report of the night.

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sql2 = 'localhost,14534'

# Where to read: the about_ topics installed with the help, and the syntax of a command.
@(Get-Help -Name about_*).Count
Get-Help -Name about_* | Where-Object -Property Name -Match 'Remote$|Classes$|Thread_Jobs' | Select-Object -ExpandProperty Name
Get-Command -Name ForEach-Object -Syntax
Get-Module -Name Pester -ListAvailable

# The answer to the request, once more: the application on sql2, and the report of the night.
Get-DbaDatabase -SqlInstance $sql2 -SqlCredential $cred -Database Planning | Format-Table -Property SqlInstance, Name, Owner, Size
Get-DbaLogin -SqlInstance $sql2 -SqlCredential $cred -Login planning_app | Format-Table -Property SqlInstance, Name, DefaultDatabase
Get-DbaAgentJob -SqlInstance $sql2 -SqlCredential $cred -Job 'Planning - nightly purge' | Format-Table -Property SqlInstance, Name, IsEnabled, LastRunOutcome, NextRunDate
pwsh -NoProfile -NonInteractive -File ./demos/module_12/05-nightly-report.ps1
Import-Csv -Path lab/nightly-report.csv | Select-Object -Last 1 -Property Start, End, ExitCode, Instances, Unreachable, ToCheck
