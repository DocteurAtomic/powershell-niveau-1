# Module 12, clip 12.3: schedule under Linux.
# Run from the root of the clone, one command at a time at the console, after
# ./demos/module_12/00-setup.ps1. The two jobs of the first part are created on sql2 and
# removed at the end of it. The crontab line of the second part is added by hand, with
# crontab -e: no script of the course changes your crontab.

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sql2 = 'localhost,14534'

# The Agent of SQL Server under Linux: a PowerShell step does not start, and the job stays
# suspended. Start-DbaAgentJob -Wait would wait for ever: no -Wait here.
New-DbaAgentJob -SqlInstance $sql2 -SqlCredential $cred -Job m12_powershell_step -OwnerLogin sa | Out-Null
New-DbaAgentJobStep -SqlInstance $sql2 -SqlCredential $cred -Job m12_powershell_step -StepName 'Morning inventory' -Subsystem PowerShell -Command 'Get-Date' | Format-Table -Property Name, SubSystem
Start-DbaAgentJob -SqlInstance $sql2 -SqlCredential $cred -Job m12_powershell_step | Format-Table -Property Name, CurrentRunStatus
Get-DbaAgentJobHistory -SqlInstance $sql2 -SqlCredential $cred -Job m12_powershell_step | Format-Table -Property StepName, Status, Message -Wrap

# A CmdExec step, which would start pwsh: refused.
New-DbaAgentJob -SqlInstance $sql2 -SqlCredential $cred -Job m12_cmdexec_step -OwnerLogin sa | Out-Null
New-DbaAgentJobStep -SqlInstance $sql2 -SqlCredential $cred -Job m12_cmdexec_step -StepName 'Morning inventory' -Subsystem CmdExec -Command 'pwsh -NoProfile -File /tmp/report.ps1' | Format-Table -Property Name, SubSystem
Start-DbaAgentJob -SqlInstance $sql2 -SqlCredential $cred -Job m12_cmdexec_step -Wait | Format-Table -Property Name, LastRunOutcome
Get-DbaAgentJobHistory -SqlInstance $sql2 -SqlCredential $cred -Job m12_cmdexec_step | Format-Table -Property StepName, Status, Message -Wrap
Remove-DbaAgentJob -SqlInstance $sql2 -SqlCredential $cred -Job m12_powershell_step, m12_cmdexec_step -WhatIf
Remove-DbaAgentJob -SqlInstance $sql2 -SqlCredential $cred -Job m12_powershell_step, m12_cmdexec_step -Confirm:$false | Format-Table -Property Name, Status

# cron, then. Which pwsh? cron searches only /usr/bin, /bin, /usr/sbin and /sbin: write the full path.
[System.Environment]::ProcessPath
Get-Command -Name pwsh -CommandType Application -All | ForEach-Object -Process { "$($_.Source)  $(& $_.Source -Version)" }

# The report of module 10 as cron starts it: from the home folder, without a console.
$pwsh = [System.Environment]::ProcessPath
$clone = (Get-Location).Path
Push-Location -Path ~
& $pwsh -NoProfile -NonInteractive -File (Join-Path $clone 'demos' 'module_10' '05-morning-inventory.ps1')
$LASTEXITCODE

# The script for the scheduler: it moves to the clone, runs the report, writes its trace.
& $pwsh -NoProfile -NonInteractive -File (Join-Path $clone 'demos' 'module_12' '05-nightly-report.ps1')
$LASTEXITCODE
Pop-Location
Import-Csv -Path lab/nightly-report.csv | Select-Object -Last 1 | Format-List

# The crontab line, every night at 6:30 (crontab -e, one line, full paths):
# 30 6 * * * /opt/microsoft/powershell/7/pwsh -NoProfile -NonInteractive -File /home/you/powershell-niveau-1/demos/module_12/05-nightly-report.ps1
