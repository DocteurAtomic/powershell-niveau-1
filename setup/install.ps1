<#
.SYNOPSIS
Installs the lab of the course: two SQL Server 2025 instances, the database, the modules.

.DESCRIPTION
1. Installs dbatools, SqlServer, SecretManagement and SecretStore at the versions the
   course is written against, for the current user, from the PowerShell Gallery, and
   downloads the help (Update-Help).
2. Downloads the backup of PachadataTraining (626 MB) and checks its SHA-256 hash.
3. Starts the two containers of compose.yaml (docker compose or podman compose).
4. Copies the backup into the shared backup volume and restores it on sql1.
5. Creates the fake backup files of the first modules (setup/new-backupfiles.ps1).

Run it again at any time: what is already done is skipped, except the restore, which only
runs when the database is missing.

.EXAMPLE
./setup/install.ps1

.EXAMPLE
./setup/install.ps1 -Engine podman
#>
[CmdletBinding()]
param(
    # The container engine: docker or podman.
    [ValidateSet('docker', 'podman')]
    [string] $Engine = 'docker',
    # The lab password of sa, the same as in compose.yaml.
    [string] $SaPassword = 'Course-2026!lab'
)
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$modules = @{
    dbatools                              = '2.9.1'
    SqlServer                             = '22.4.5.1'
    'Microsoft.PowerShell.SecretManagement' = '1.1.2'
    'Microsoft.PowerShell.SecretStore'      = '1.0.6'
}
foreach ($name in $modules.Keys) {
    $version = $modules[$name]
    if (-not (Get-InstalledPSResource -Name $name -Version $version -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $name $version..."
        Install-PSResource -Name $name -Version $version -Scope CurrentUser -TrustRepository
    }
}
Import-Module dbatools -RequiredVersion $modules.dbatools

# PowerShell 7 ships without the full help: Get-Help -Examples shows nothing until it is
# downloaded. A module whose help cannot be downloaded is not an error here.
Write-Host 'Downloading the help of PowerShell (about 20 seconds)...'
Update-Help -Scope CurrentUser -UICulture en-US -ErrorAction SilentlyContinue

$backup = 'setup/backup/PachadataTraining-2026-10.bak'
$url = 'https://files.pachadata.com/public/api/raw?hash=tAsyC50c6kfVadBp3zc6TQ&file=/PachadataTraining/SqlServer/PachadataTraining-2026-10.bak'
$sha256 = '1D05970D8E0576CD0C57BDDBA64C2BA8A583845AD4744ADEB75D2EA4A3F7D44E'
if (-not (Test-Path $backup)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
    Write-Host 'Downloading PachadataTraining-2026-10.bak (626 MB)...'
    Invoke-WebRequest -Uri $url -OutFile "$backup.part"
    Move-Item "$backup.part" $backup
}
if ((Get-FileHash $backup -Algorithm SHA256).Hash -ne $sha256) {
    throw "Checksum mismatch for $backup : delete it and run this script again."
}

& $Engine compose up -d --wait
if ($LASTEXITCODE -ne 0) { throw "$Engine compose up failed (exit code $LASTEXITCODE)." }

# A new volume can belong to root (Docker): SQL Server, which runs as mssql, could not write
# its backups there.
& $Engine exec -u 0 pwshcourse chown -R mssql /var/opt/mssql/backup
if ($LASTEXITCODE -ne 0) { throw "chown of the backup volume failed." }

Set-DbatoolsInsecureConnection -SessionOnly | Out-Null
$cred = [pscredential]::new('sa', (ConvertTo-SecureString $SaPassword -AsPlainText -Force))
if (-not (Get-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred -Database PachadataTraining)) {
    & $Engine cp $backup 'pwshcourse:/var/opt/mssql/backup/PachadataTraining-2026-10.bak'
    if ($LASTEXITCODE -ne 0) { throw "Copy of the backup into pwshcourse failed." }
    & $Engine exec -u 0 pwshcourse chown mssql /var/opt/mssql/backup/PachadataTraining-2026-10.bak
    Restore-DbaDatabase -SqlInstance 'localhost,14533' -SqlCredential $cred `
        -Path /var/opt/mssql/backup/PachadataTraining-2026-10.bak `
        -DatabaseName PachadataTraining `
        -DestinationDataDirectory /var/opt/mssql/data -DestinationLogDirectory /var/opt/mssql/data `
        -EnableException | Out-Null
    # The backup is at level 160 (built on SQL Server 2022); the course runs at level 170.
    Set-DbaDbCompatibility -SqlInstance 'localhost,14533' -SqlCredential $cred `
        -Database PachadataTraining -Compatibility 170 | Out-Null
    # The reference backup stays in setup/backup on this computer. Out of the shared volume,
    # no command of the course can restore it again or delete it by mistake.
    & $Engine exec -u 0 pwshcourse rm -f /var/opt/mssql/backup/PachadataTraining-2026-10.bak
}

./setup/new-backupfiles.ps1
./setup/test-lab.ps1 -SaPassword $SaPassword
