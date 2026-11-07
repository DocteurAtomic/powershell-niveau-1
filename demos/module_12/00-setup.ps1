<#
.SYNOPSIS
Creates the planning application on sql1 and the finance_report login on sql2, the lab state that module 12 assumes.

.DESCRIPTION
Module 12 moves an application from one instance to the other. On sql1 (localhost,14533),
the script creates what the planning application uses: the database Planning (two tables,
dbo.Room and dbo.Booking), the SQL login planning_app with its user in Planning, and the
SQL Server Agent job "Planning - nightly purge", whose T-SQL step deletes the bookings that
ended more than two years ago. On sql2 (localhost,14534), for the exercise, it creates the
SQL login finance_report and its user, a reader, in the database Finance of module 10.

It first runs ./demos/module_10/00-setup.ps1, which creates the PachaOps vault and the
database Finance on sql2 when they are missing.

The two logins get a random password, generated here and kept only in the vault, as the
secrets planning-app and finance-report: no script of the course writes it. The script does
nothing for what already exists. ./demos/module_12/99-cleanup.ps1 removes all of it.

.EXAMPLE
./demos/module_12/00-setup.ps1
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot '..' 'module_10' '00-setup.ps1') | Out-Null
$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$sql1 = 'localhost,14533'
$sql2 = 'localhost,14534'

# The password of an application login: random, stored in the vault, never written in a file.
function Get-AppCredential {
    param([string] $Name, [string] $UserName)
    $secret = try { Get-Secret -Name $Name -Vault PachaOps -ErrorAction Stop } catch { $null }
    if ($secret -is [pscredential]) { return $secret }
    $random = [System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(18))
    # Base64 gives letters and digits; the suffix makes sure of the four kinds of the password policy.
    $password = ConvertTo-SecureString -String ($random.Replace('/', 'x').Replace('+', 'y') + '-7Kq') -AsPlainText -Force
    $secret = [pscredential]::new($UserName, $password)
    Set-Secret -Name $Name -Secret $secret -Vault PachaOps
    # A login left by an earlier lab, whose secret is gone: give it the new password.
    foreach ($instance in $sql1, $sql2) {
        if (Get-DbaLogin -SqlInstance $instance -SqlCredential $cred -Login $UserName -EnableException) {
            Set-DbaLogin -SqlInstance $instance -SqlCredential $cred -Login $UserName -SecurePassword $password -EnableException | Out-Null
        }
    }
    $secret
}

# 1. The planning application on sql1.
$planning = Get-AppCredential -Name planning-app -UserName planning_app
if (Get-DbaDatabase -SqlInstance $sql1 -SqlCredential $cred -Database Planning -EnableException) {
    'ok    the database Planning already exists on sql1'
}
else {
    New-DbaDatabase -SqlInstance $sql1 -SqlCredential $cred -Name Planning -RecoveryModel Simple -EnableException | Out-Null
    $tables = @'
CREATE TABLE dbo.Room (
    RoomId int NOT NULL CONSTRAINT PK_Room PRIMARY KEY,
    Name nvarchar(40) NOT NULL,
    Seats tinyint NOT NULL
);
CREATE TABLE dbo.Booking (
    BookingId int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Booking PRIMARY KEY,
    RoomId int NOT NULL CONSTRAINT FK_Booking_Room REFERENCES dbo.Room (RoomId),
    SessionCode char(8) NOT NULL,
    StartDate date NOT NULL,
    EndDate date NOT NULL
);
INSERT INTO dbo.Room (RoomId, Name, Seats)
VALUES (1, N'Montparnasse', 12), (2, N'Bastille', 8), (3, N'Opéra', 16), (4, N'Nation', 10);
INSERT INTO dbo.Booking (RoomId, SessionCode, StartDate, EndDate)
SELECT n.Number % 4 + 1,
       CONCAT('S', RIGHT(CONCAT('0000000', n.Number), 7)),
       DATEADD(day, -3 * n.Number, '20261102'),
       DATEADD(day, -3 * n.Number + n.Number % 5, '20261102')
FROM (SELECT TOP (400) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Number
      FROM sys.all_objects) AS n;
ALTER DATABASE Planning SET READ_COMMITTED_SNAPSHOT ON;
'@
    Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Database Planning -Query $tables -EnableException
    'ok    the database Planning is created on sql1'
}
if (-not (Get-DbaLogin -SqlInstance $sql1 -SqlCredential $cred -Login planning_app -EnableException)) {
    New-DbaLogin -SqlInstance $sql1 -SqlCredential $cred -Login planning_app -SecurePassword $planning.Password -DefaultDatabase Planning -EnableException | Out-Null
    'ok    the login planning_app is created on sql1'
}
if (-not (Get-DbaDbUser -SqlInstance $sql1 -SqlCredential $cred -Database Planning -User planning_app -EnableException)) {
    New-DbaDbUser -SqlInstance $sql1 -SqlCredential $cred -Database Planning -Login planning_app -User planning_app -EnableException | Out-Null
    Add-DbaDbRoleMember -SqlInstance $sql1 -SqlCredential $cred -Database Planning -Role db_datareader, db_datawriter -Member planning_app -Confirm:$false -EnableException | Out-Null
}
$job = 'Planning - nightly purge'
if (Get-DbaAgentJob -SqlInstance $sql1 -SqlCredential $cred -Job $job -EnableException) {
    "ok    the job $job already exists on sql1"
}
else {
    New-DbaAgentJob -SqlInstance $sql1 -SqlCredential $cred -Job $job -OwnerLogin sa -Description 'Deletes the bookings that ended more than two years ago.' -EnableException | Out-Null
    $purge = 'DELETE FROM dbo.Booking WHERE EndDate < DATEADD(year, -2, CAST(SYSDATETIME() AS date));'
    New-DbaAgentJobStep -SqlInstance $sql1 -SqlCredential $cred -Job $job -StepName 'Delete old bookings' -Subsystem TransactSql -Database Planning -Command $purge -EnableException | Out-Null
    New-DbaAgentSchedule -SqlInstance $sql1 -SqlCredential $cred -Job $job -Schedule 'Planning - every night' -FrequencyType Daily -FrequencyInterval 1 -StartTime '023000' -Force -EnableException | Out-Null
    "ok    the job $job is created on sql1"
}

# 2. For the exercise: the login finance_report on sql2, a reader of Finance.
$finance = Get-AppCredential -Name finance-report -UserName finance_report
if (-not (Get-DbaLogin -SqlInstance $sql2 -SqlCredential $cred -Login finance_report -EnableException)) {
    New-DbaLogin -SqlInstance $sql2 -SqlCredential $cred -Login finance_report -SecurePassword $finance.Password -DefaultDatabase Finance -EnableException | Out-Null
    'ok    the login finance_report is created on sql2'
}
if (-not (Get-DbaDbUser -SqlInstance $sql2 -SqlCredential $cred -Database Finance -User finance_report -EnableException)) {
    New-DbaDbUser -SqlInstance $sql2 -SqlCredential $cred -Database Finance -Login finance_report -User finance_report -EnableException | Out-Null
    Add-DbaDbRoleMember -SqlInstance $sql2 -SqlCredential $cred -Database Finance -Role db_datareader -Member finance_report -Confirm:$false -EnableException | Out-Null
}
'ok    the lab of module 12 is ready'
