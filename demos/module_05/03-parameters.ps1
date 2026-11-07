# ci: skip. Path is mandatory: run alone, the script asks for it.

<#
.SYNOPSIS
Shows the values its parameters receive. Module 5, clip 5.2.

.EXAMPLE
./demos/module_05/03-parameters.ps1 -Path lab/backups/sql1 -MaxAgeHours 48 -IssuesOnly
#>
param(
    # The folder of one instance on the backup share.
    [Parameter(Mandatory)]
    [string] $Path,

    # The age, in hours, beyond which a backup is late.
    [int] $MaxAgeHours = 24,

    # The moment the report is written for; now by default.
    [datetime] $ReferenceDate = (Get-Date),

    # Return only the databases that need a look.
    [switch] $IssuesOnly
)

[pscustomobject]@{
    Path          = $Path
    MaxAgeHours   = $MaxAgeHours
    ReferenceDate = $ReferenceDate
    IssuesOnly    = $IssuesOnly
}
