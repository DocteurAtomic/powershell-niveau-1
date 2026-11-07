# Module 8, clip 8.1: the modules of the session and of the workstation, the folders where
# PowerShell looks for them, and the two ways a module is loaded. Typed one command at a
# time at the console, from the root of the clone.

# The modules loaded in this session, then the modules installed on the workstation.
Get-Module
Get-Module -ListAvailable
$env:PSModulePath -split [System.IO.Path]::PathSeparator

# Autoloading: the first use of a command imports its module.
Get-Module -Name Microsoft.PowerShell.Archive
Compress-Archive -Path lab/backups/sql1/Finance/FULL/*.bak -DestinationPath lab/finance-full.zip
Get-Module -Name Microsoft.PowerShell.Archive
Get-Item -Path lab/finance-full.zip | Select-Object -Property Name, Length
Remove-Item -Path lab/finance-full.zip

# Import-Module loads a module by its name, and Get-Command lists what it brings.
Import-Module -Name dbatools
Get-Module -Name dbatools | Select-Object -Property Name, Version, ModuleType, ModuleBase
(Get-Command -Module dbatools).Count
Get-Command -Module dbatools -Verb Test -Noun *Backup*
