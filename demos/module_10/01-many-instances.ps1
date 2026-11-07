# Module 10, clip 10.1: one command, several instances.
# Run from the root of the clone, one command at a time at the console, after
# ./demos/module_10/00-setup.ps1 (the secret sql-lab and the database Finance on sql2).

$cred = Get-Secret -Name sql-lab
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$lab = 'localhost,14533', 'localhost,14534'

# -SqlInstance takes an array: one call, both instances.
Get-DbaInstanceProperty -SqlInstance $lab -SqlCredential $cred -InstanceProperty VersionString, Edition, HostPlatform | Format-Table -Property SqlInstance, Name, Value
(Get-DbaInstanceProperty -SqlInstance 'localhost,14533' -SqlCredential $cred).Count
Get-DbaBuild -SqlInstance $lab -SqlCredential $cred | Format-Table -Property SqlInstance, Build, NameLevel, SPLevel, CULevel, KBLevel

# The databases, as SMO objects.
Get-DbaDatabase -SqlInstance $lab -SqlCredential $cred -ExcludeSystem | Format-Table -Property SqlInstance, Name, Status, RecoveryModel, SizeMB
$finance = Get-DbaDatabase -SqlInstance 'localhost,14534' -SqlCredential $cred -Database Finance
$finance.GetType().FullName
($finance | Get-Member -MemberType Property).Count

# The inventory of the team: the CSV rows do not go down the pipeline into -SqlInstance.
$inventory = Import-Csv -Path data/instances.csv
$inventory | Format-Table -Property Name, SqlInstance, Environment
$labInventory = $inventory | Where-Object -Property SqlInstance -Like -Value 'localhost,*'
$labInventory | Get-DbaDatabase -SqlCredential $cred -ExcludeSystem
Get-Help -Name Get-DbaDatabase -Parameter SqlInstance
$labInventory.SqlInstance
Get-DbaDatabase -SqlInstance $labInventory.SqlInstance -SqlCredential $cred -ExcludeSystem | Format-Table -Property SqlInstance, Name, SizeMB
$labInventory | Select-Object -ExpandProperty SqlInstance | Get-DbaDatabase -SqlCredential $cred -ExcludeSystem | Format-Table -Property SqlInstance, Name, SizeMB
