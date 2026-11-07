# Module 12, clip 12.2: copy a login and a job.
# Run from the root of the clone, one command at a time at the console, after clip 12.1 (the
# database Planning on sql2, with its orphaned user planning_app). The password of
# planning_app is in the vault, as the secret planning-app that 00-setup.ps1 created.

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sql1 = 'localhost,14533'
$sql2 = 'localhost,14534'
$app = Get-Secret -Name planning-app
$sid = @{ Name = 'Sid'; Expression = { [System.Convert]::ToHexString($_.Sid) } }

# By hand, as in SSMS: the same name, the same password, and a new SID. The user stays orphaned.
New-DbaLogin -SqlInstance $sql2 -SqlCredential $cred -Login planning_app -SecurePassword $app.Password -DefaultDatabase Planning | Format-Table -Property SqlInstance, Name, LoginType
Get-DbaLogin -SqlInstance $sql1, $sql2 -SqlCredential $cred -Login planning_app | Format-Table -Property SqlInstance, Name, $sid
Get-DbaDbOrphanUser -SqlInstance $sql2 -SqlCredential $cred | Format-Table -Property SqlInstance, DatabaseName, User
Repair-DbaDbOrphanUser -SqlInstance $sql2 -SqlCredential $cred -WhatIf

# Rather the login of sql1, with its SID: the login made by hand goes, -WhatIf first.
Remove-DbaLogin -SqlInstance $sql2 -SqlCredential $cred -Login planning_app -WhatIf
Remove-DbaLogin -SqlInstance $sql2 -SqlCredential $cred -Login planning_app -Confirm:$false | Format-Table -Property SqlInstance, Name, Status

# Copy-DbaLogin: the hashed password and the SID of the source.
Copy-DbaLogin -Source $sql1 -SourceSqlCredential $cred -Destination $sql2 -DestinationSqlCredential $cred -Login planning_app -WhatIf
Copy-DbaLogin -Source $sql1 -SourceSqlCredential $cred -Destination $sql2 -DestinationSqlCredential $cred -Login planning_app | Format-Table -Property Name, Type, Status, Notes
Get-DbaLogin -SqlInstance $sql1, $sql2 -SqlCredential $cred -Login planning_app | Format-Table -Property SqlInstance, Name, DefaultDatabase, $sid
Get-DbaDbOrphanUser -SqlInstance $sql2 -SqlCredential $cred
Invoke-DbaQuery -SqlInstance $sql2 -SqlCredential $app -Database Planning -Query 'SELECT COUNT(*) AS Bookings FROM dbo.Booking;'

# The job last: it needs the database and its owner on the destination. Disabled on sql1.
Copy-DbaAgentJob -Source $sql1 -SourceSqlCredential $cred -Destination $sql2 -DestinationSqlCredential $cred -Job 'Planning - nightly purge' -DisableOnSource -WhatIf
Copy-DbaAgentJob -Source $sql1 -SourceSqlCredential $cred -Destination $sql2 -DestinationSqlCredential $cred -Job 'Planning - nightly purge' -DisableOnSource | Format-Table -Property Name, Type, Status, Notes
Get-DbaAgentJob -SqlInstance $sql1, $sql2 -SqlCredential $cred -Job 'Planning - nightly purge' | Format-Table -Property SqlInstance, Name, IsEnabled, OwnerLoginName, NextRunDate
Start-DbaAgentJob -SqlInstance $sql2 -SqlCredential $cred -Job 'Planning - nightly purge' -Wait | Format-Table -Property SqlInstance, Name, CurrentRunStatus, LastRunOutcome
Get-DbaAgentJobHistory -SqlInstance $sql2 -SqlCredential $cred -Job 'Planning - nightly purge' | Format-Table -Property StepName, Status, Message -Wrap
