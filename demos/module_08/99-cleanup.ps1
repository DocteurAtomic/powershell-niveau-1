# Module 8: removes what the demos created, the module PachaBackup from your module folder and
# lab/modules. PSScriptAnalyzer, installed in clip 8.2, stays installed: level 2 uses it.
Remove-Module -Name PachaBackup -ErrorAction SilentlyContinue
$userModules = ($env:PSModulePath -split [System.IO.Path]::PathSeparator)[0]
Remove-Item -Path (Join-Path -Path $userModules -ChildPath PachaBackup) -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path lab/modules -Recurse -Force -ErrorAction SilentlyContinue
