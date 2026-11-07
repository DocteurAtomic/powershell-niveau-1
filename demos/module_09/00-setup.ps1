<#
.SYNOPSIS
Creates the PachaOps vault and its sql-lab secret when they are missing.

.DESCRIPTION
Clip 9.1 creates them by hand, at the console. This script does the same without a prompt,
for the continuous integration and for a computer where the clip was not followed: it
registers a SecretStore vault named PachaOps, configures SecretStore without a password
(a lab setting, see clip 9.1), and stores the sa login of the lab as the secret sql-lab.

It does nothing when sql-lab can already be read. It refuses to touch a SecretStore that
already exists on the account and asks for a password, because resetting it would erase its
secrets: add the secret by hand, as in clip 9.1.

The lab password is read from the environment variable MSSQL_SA_PASSWORD, as compose.yaml
does, and otherwise from the default value written in compose.yaml: no script of the
course repeats it.

.EXAMPLE
./demos/module_09/00-setup.ps1
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

# Get-Secret stops on a vault that is not registered, or on a store that asks for a password.
$secret = try { Get-Secret -Name sql-lab -Vault PachaOps -WarningAction SilentlyContinue } catch { $null }
if ($secret -is [pscredential]) {
    'ok    the secret sql-lab can be read from the vault PachaOps'
    return
}

# The folder where SecretStore keeps its files, for the current user. A store that already
# exists is reset only if it asks for no password, as clip 9.1 configures it; otherwise it
# may hold secrets of its own, and Reset-SecretStore would erase them.
$store = if ($IsWindows) {
    Join-Path ([System.Environment]::GetFolderPath('LocalApplicationData')) 'Microsoft' 'PowerShell' 'secretmanagement' 'localstore'
} else {
    Join-Path $HOME '.secretmanagement' 'localstore'
}
$reset = $true
if (Get-ChildItem -Path $store -File -ErrorAction SilentlyContinue) {
    $pwsh = [System.Environment]::ProcessPath
    $authentication = & $pwsh -NoProfile -NonInteractive -Command '(Get-SecretStoreConfiguration).Authentication.ToString()' 2> $null
    if ($authentication -ne 'None') {
        throw "A SecretStore that asks for a password already exists on this account ($store). Add the secret by hand, as in clip 9.1: Set-Secret -Name sql-lab -Secret (Get-Credential -UserName sa)"
    }
    $reset = $false
}

$password = $env:MSSQL_SA_PASSWORD
if (-not $password) {
    $compose = Get-Content -Path (Join-Path $PSScriptRoot '..' '..' 'compose.yaml') -Raw
    if ($compose -notmatch 'MSSQL_SA_PASSWORD:-([^}]+)\}') {
        throw 'No lab password: set MSSQL_SA_PASSWORD, or follow clip 9.1.'
    }
    $password = $Matches[1]
}

if ($reset) {
    Reset-SecretStore -Authentication None -Interaction None -Force -WarningAction SilentlyContinue | Out-Null
}
if (-not (Get-SecretVault -Name PachaOps -ErrorAction SilentlyContinue)) {
    Register-SecretVault -Name PachaOps -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
}
$credential = [pscredential]::new('sa', (ConvertTo-SecureString -String $password -AsPlainText -Force))
Set-Secret -Name sql-lab -Secret $credential -Vault PachaOps
'ok    the vault PachaOps and the secret sql-lab are created'
