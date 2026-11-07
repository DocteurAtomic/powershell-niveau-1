# ci: skip. Windows only: the ScheduledTasks module comes with Windows, not with PowerShell.

# Module 12, clip 12.3, the Windows sequence: the Task Scheduler.
# Run from the root of the clone, in PowerShell 7 (pwsh), one command at a time. The task runs
# the same script as cron, at 6:30 every day, under your account, while you are logged on.

$pwsh = [System.Environment]::ProcessPath
$script = (Resolve-Path -Path ./demos/module_12/05-nightly-report.ps1).Path
$action = New-ScheduledTaskAction -Execute $pwsh -Argument "-NoProfile -NonInteractive -File `"$script`""
$trigger = New-ScheduledTaskTrigger -Daily -At '06:30'
Register-ScheduledTask -TaskName 'PachaOps morning inventory' -Action $action -Trigger $trigger
Start-ScheduledTask -TaskName 'PachaOps morning inventory'
Get-ScheduledTaskInfo -TaskName 'PachaOps morning inventory' | Select-Object -Property LastRunTime, LastTaskResult, NextRunTime
Import-Csv -Path lab/nightly-report.csv | Select-Object -Last 1 | Format-List

# The task goes when the module is done.
Unregister-ScheduledTask -TaskName 'PachaOps morning inventory' -Confirm:$false
