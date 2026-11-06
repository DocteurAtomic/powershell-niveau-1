# Module 1, clip 1.3: the help and the parameters.
# Run from the root of the clone, one command at a time at the console.
# The full help is not shipped with PowerShell 7: setup/install.ps1 downloads it with
# Update-Help. Without it, Get-Help shows a partial help and -Examples shows nothing.

# The help of a cmdlet, then its examples, then three of its parameters.
Get-Help -Name Get-ChildItem
Get-Help -Name Get-ChildItem -Examples
Get-Help -Name Get-ChildItem -Parameter Path, Filter, Recurse

# The syntax read from the command itself, on this system, in the order of the positions.
Get-Command -Name Get-ChildItem -Syntax

# -CodeSigningCert is in the help file, but it belongs to the certificate provider of
# Windows: on a folder, the parameter does not exist.
Get-ChildItem -Path lab/backups/sql1/Finance -CodeSigningCert

# Named parameters, then the same command with positional values: the same files.
Get-ChildItem -Path lab/backups/sql1/Finance -Filter *.bak -Recurse
Get-ChildItem lab/backups/sql1/Finance *.bak -Recurse

# The online help opens in the default browser, which a script should not do:
# Get-Help -Name Get-ChildItem -Online
