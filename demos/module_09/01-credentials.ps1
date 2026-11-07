# ci: skip. Get-Credential and Reset-SecretStore wait for an answer at the console.

# Module 9, clip 9.1: a credential, and the vault that keeps it for the scripts.
# Run from the root of the clone, one command at a time at the console. Get-Credential asks
# for the password of sa: type the lab password, the one of compose.yaml.

# A credential: a user name and a SecureString, never a password written in the script.
$cred = Get-Credential -UserName sa
$cred
$cred | Get-Member -MemberType Property

# Another process does not see the variable, and cannot ask for the password either.
pwsh -NoProfile -Command '$null -eq $cred'
pwsh -NoProfile -NonInteractive -Command 'Get-Credential -UserName sa'

# Export-Clixml under Linux: the SecureString is written as the hexadecimal of its text.
# A throwaway credential, demo, with the password pacha, which protects nothing.
$demo = Get-Credential -UserName demo
$demo | Export-Clixml -Path lab/demo-credential.xml
Get-Content -Path lab/demo-credential.xml
[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromHexString('70006100630068006100'))
Remove-Item -Path lab/demo-credential.xml

# The vault: SecretManagement registers it, SecretStore keeps the secrets in a file.
Get-SecretVault
Register-SecretVault -Name PachaOps -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Get-SecretVault

# A lab setting: no password to open the store. Reset-SecretStore erases what the store
# holds; on an account that already uses SecretStore, skip it and only add the secret.
# Measured with SecretStore 1.0.6: -WhatIf does not stop it. It still asks, and Y erases the
# secrets. Answer N to the first command, Y to the second.
Reset-SecretStore -Authentication None -Interaction None -WhatIf
Reset-SecretStore -Authentication None -Interaction None

# The secret, then read back from a new process, without a console.
Set-Secret -Name sql-lab -Secret $cred
Get-SecretInfo
pwsh -NoProfile -NonInteractive -Command '(Get-Secret -Name sql-lab).UserName'
Get-ChildItem -Path ~/.secretmanagement -Recurse -File | Select-Object -Property Name, Length
