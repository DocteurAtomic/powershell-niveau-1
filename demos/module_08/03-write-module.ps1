# Module 8, clip 8.3: the functions of module 6 become a script module, PachaBackup, with its
# manifest. Typed one command at a time at the console, from the root of the clone. The
# module is built under lab/modules, which Git ignores; 04-install-module.ps1 installs it.

# A .psm1 file is a script module: the same functions, another extension.
Copy-Item -Path demos/module_06/backup-functions.ps1 -Destination lab/PachaBackup.psm1
Import-Module -Name ./lab/PachaBackup.psm1 -PassThru
Get-Command -Module PachaBackup

# Export-ModuleMember chooses what the module shows; the other functions stay inside it.
Add-Content -Path lab/PachaBackup.psm1 -Value 'Export-ModuleMember -Function Remove-OldBackup'
Import-Module -Name ./lab/PachaBackup.psm1 -Force -PassThru
Get-OldBackup -Path lab/backups -RetentionDays 28
Remove-OldBackup -Path lab/backups/sql1/DBA -RetentionDays 28 -ReferenceDate 2026-11-02 -WhatIf
Remove-Module -Name PachaBackup
Remove-Item -Path lab/PachaBackup.psm1

# The folder of the module has its name, and a subfolder per version.
$folder = 'lab/modules/PachaBackup/0.1.0'
$null = New-Item -ItemType Directory -Path $folder -Force
Copy-Item -Path demos/module_06/backup-functions.ps1 -Destination $folder/PachaBackup.psm1

# The manifest, written by New-ModuleManifest from a hashtable (splatting: @ instead of $).
$manifest = @{
    Path              = "$folder/PachaBackup.psd1"
    RootModule        = 'PachaBackup.psm1'
    ModuleVersion     = '0.1.0'
    Author            = 'PachaData operations team'
    Description       = 'The functions of the backup share: old backups, summary, retention.'
    FunctionsToExport = 'Get-OldBackup', 'Get-BackupSummary', 'Remove-OldBackup'
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
New-ModuleManifest @manifest
Get-Content -Path $folder/PachaBackup.psd1 | Select-String -Pattern '^(RootModule|ModuleVersion|FunctionsToExport)'
Test-ModuleManifest -Path $folder/PachaBackup.psd1
Import-Module -Name ./$folder/PachaBackup.psd1 -PassThru
