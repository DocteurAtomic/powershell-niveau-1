# Module 6, clip 6.1: a function in a file. Run it with ./ and the function is gone with the
# script scope; dot-source it, and it stays in the session:
#   . ./demos/module_06/old-backups.ps1

function Get-OldBackup {
    param(
        [string] $Path,
        [int] $RetentionDays,
        [datetime] $ReferenceDate = (Get-Date)
    )
    $limit = $ReferenceDate.AddDays(-$RetentionDays)
    Get-ChildItem -Path $Path -Recurse -File -Include *.bak, *.trn |
        Where-Object -Property LastWriteTime -LT -Value $limit
}
