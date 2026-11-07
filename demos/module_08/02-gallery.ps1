# ci: skip. Installs PSScriptAnalyzer from the PowerShell Gallery, and the first install
# asks a question (answer N in the video).
# Module 8, clip 8.2: find a module in the PowerShell Gallery, install it at a fixed version,
# then run it on the morning report. Typed one command at a time, from the root of the clone.

Get-PSResourceRepository
Find-PSResource -Name PSScriptAnalyzer |
    Select-Object -Property Name, Version, Author, PublishedDate, ProjectUri

# PSGallery is not trusted: Install-PSResource asks first.
Install-PSResource -Name PSScriptAnalyzer -Version 1.25.0
Install-PSResource -Name PSScriptAnalyzer -Version 1.25.0 -TrustRepository
Get-InstalledPSResource -Name PSScriptAnalyzer, dbatools, SqlServer

# install.ps1 installs the modules of the course the same way, at fixed versions.
Select-String -Path setup/install.ps1 -Pattern 'PSResource'

# The analyzer on the morning report of module 5, then on the whole folder.
Invoke-ScriptAnalyzer -Path demos/module_05/06-backup-report.ps1
Invoke-ScriptAnalyzer -Path demos/module_05

# PowerShellGet 2 and Install-Module ship with PowerShell 7.6 too.
Get-Command -Name Install-Module, Install-PSResource
