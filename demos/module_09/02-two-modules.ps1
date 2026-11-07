# ci: skip. Connect-DbaInstance stops on purpose before Set-DbatoolsInsecureConnection.

# Module 9, clip 9.2: the SqlServer module and dbatools, and the order they load in.
# Run from the root of the clone, one command at a time at the console, in a new pwsh: the
# secret sql-lab of clip 9.1 must exist (or run ./demos/module_09/00-setup.ps1).

# Two modules for SQL Server, installed by setup/install.ps1. Counting the commands of a
# module imports it: dbatools first, always.
Get-Module -ListAvailable -Name dbatools, SqlServer | Select-Object -Property Name, Version
(Get-Command -Module dbatools).Count
(Get-Command -Module SqlServer).Count

# In a new session, SqlServer first: Invoke-Sqlcmd works, then dbatools cannot load.
pwsh -NoProfile -Command {
    $cred = Get-Secret -Name sql-lab
    Invoke-Sqlcmd -ServerInstance 'localhost,14533' -Credential $cred -TrustServerCertificate -Query 'SELECT SUSER_SNAME() AS LoginName;'
    Get-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Database master
}

# In a new session, dbatools first: both work.
pwsh -NoProfile -Command {
    $cred = Get-Secret -Name sql-lab
    Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
    Get-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Database master | Format-Table -Property Name, RecoveryModel
    Invoke-Sqlcmd -ServerInstance 'localhost,14533' -Credential $cred -TrustServerCertificate -Query 'SELECT SUSER_SNAME() AS LoginName;' | Format-Table
}

# Connect-DbaInstance, and the self-signed certificate of the container.
$cred = Get-Secret -Name sql-lab
$sql1 = 'localhost,14533'
Connect-DbaInstance -SqlInstance $sql1 -SqlCredential $cred
Set-DbatoolsInsecureConnection -SessionOnly | Select-Object -Property FullName, Value
$server = Connect-DbaInstance -SqlInstance $sql1 -SqlCredential $cred
$server.GetType().FullName
$server | Select-Object -Property Name, VersionString, Edition, HostPlatform
$server.Databases.Name
