# Module 8, clip 8.4: PachaBackup installed for the current user and loaded by its name, then
# a script that calls it with -WhatIf. Run after 03-write-module.ps1, one command at a time,
# from the root of the clone, with the backup files created for 2 November 2026. The unsafe
# script really removes 30 files, and the share is created again right after.
# 99-cleanup.ps1 uninstalls the module.

# The first folder of PSModulePath is the one of the current user.
$userModules = ($env:PSModulePath -split [System.IO.Path]::PathSeparator)[0]
$userModules
Copy-Item -Path lab/modules/PachaBackup -Destination $userModules -Recurse -Force
Get-Module -ListAvailable -Name PachaBackup

# Installed in a module folder, it loads by its name, or by itself at the first command.
Remove-Module -Name PachaBackup -ErrorAction SilentlyContinue
Get-Command -Name Remove-OldBackup
Get-Module -Name PachaBackup | Select-Object -Property Name, Version, ModuleBase
Import-Module -Name PachaBackup -RequiredVersion 0.2.0

# A script that calls the module: -WhatIf does not reach a function of a script module.
Get-Content -Path demos/module_08/retention-job-unsafe.ps1 | Select-Object -Last 3
./demos/module_08/retention-job-unsafe.ps1 -ReferenceDate 2026-11-02 -WhatIf
(Get-ChildItem -Path lab/backups -Recurse -File).Count
./setup/new-backupfiles.ps1 -ReferenceDate 2026-11-02

# The script passes its -WhatIf to the function itself.
Get-Content -Path demos/module_08/retention-job.ps1 | Select-Object -Last 3
./demos/module_08/retention-job.ps1 -ReferenceDate 2026-11-02 -WhatIf
(Get-ChildItem -Path lab/backups -Recurse -File).Count
