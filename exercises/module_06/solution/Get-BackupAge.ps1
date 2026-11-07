# Solution of the exercise of module 6.

function Get-BackupAge {
    <#
    .SYNOPSIS
    Adds to each backup file its age in days.

    .DESCRIPTION
    Takes files from the pipeline, such as the output of Get-ChildItem, and returns each of
    them with one more property, AgeDays: the days between its last write and the reference
    date, rounded to two decimals.

    .EXAMPLE
    Get-ChildItem -Path lab/backups/sql1/Finance -Recurse -File -Filter *.bak | Get-BackupAge
    #>
    [CmdletBinding()]
    param(
        # The backup files, from Get-ChildItem.
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.IO.FileInfo] $File,

        # The moment the age is computed for; now by default.
        [datetime] $ReferenceDate = (Get-Date)
    )
    process {
        $age = [math]::Round(($ReferenceDate - $File.LastWriteTime).TotalDays, 2)
        Write-Verbose "$($File.Name): $age days"
        $File | Add-Member -NotePropertyName AgeDays -NotePropertyValue $age -PassThru
    }
}
