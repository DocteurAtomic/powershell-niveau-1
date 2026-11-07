# Solution of the exercise of module 8: PachaOps 0.1.0, the module of the PachaData
# operations team. Get-BackupAge comes from the exercise of module 6; Get-OldBackup,
# Get-BackupSummary and Remove-OldBackup from demos/module_06/backup-functions.ps1.
# The manifest, PachaOps.psd1, lists the exported functions.

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

function Get-OldBackup {
    <#
    .SYNOPSIS
    Returns the backup files older than the retention.

    .DESCRIPTION
    Searches a folder of the backup share recursively for backup files (.bak and .trn) and
    returns those written before the reference date minus the retention. Other files, such
    as a README, are never returned. The type of a backup is the name of its folder (FULL,
    DIFF or LOG), as in Ola Hallengren's Maintenance Solution.

    .EXAMPLE
    Get-OldBackup -Path lab/backups -RetentionDays 28

    .EXAMPLE
    Get-OldBackup -Path lab/backups/sql1 -RetentionDays 7 -Type LOG -Verbose
    #>
    [CmdletBinding()]
    param(
        # The folder of the backups, searched recursively.
        [Parameter(Mandatory)]
        [string] $Path,

        # Files written more than this number of days before the reference date are returned.
        [Parameter(Mandatory)]
        [ValidateRange(1, 3650)]
        [int] $RetentionDays,

        # The backup types to look at. All three by default.
        [ValidateSet('FULL', 'DIFF', 'LOG')]
        [string[]] $Type = ('FULL', 'DIFF', 'LOG'),

        # The moment the retention is computed from; now by default.
        [datetime] $ReferenceDate = (Get-Date)
    )
    $limit = $ReferenceDate.AddDays(-$RetentionDays)
    Write-Verbose "Limit: $($limit.ToString('yyyy-MM-dd HH:mm'))"
    $files = Get-ChildItem -Path $Path -Recurse -File -Include *.bak, *.trn |
        Where-Object -FilterScript { $_.Directory.Name -in $Type }
    Write-Verbose "$(@($files).Count) backup files of type $($Type -join ', ') under $Path"
    $files | Where-Object -Property LastWriteTime -LT -Value $limit
}

function Get-BackupSummary {
    <#
    .SYNOPSIS
    Returns, for each instance, the number and the size of its files on the backup share.

    .DESCRIPTION
    Takes instance names from the pipeline, as strings or as objects with a Name property,
    such as the rows of data/instances.csv. Returns one object per instance, with a file
    count of 0 when the instance has no folder on the share.

    .EXAMPLE
    'sql1', 'sql2' | Get-BackupSummary

    .EXAMPLE
    Import-Csv -Path data/instances.csv | Get-BackupSummary
    #>
    [CmdletBinding()]
    param(
        # The name of the instance, which is also the name of its folder on the share.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]] $Name,

        # The root of the backup share.
        [string] $Root = 'lab/backups'
    )
    begin {
        $total = 0
    }
    process {
        foreach ($instance in $Name) {
            $folder = Join-Path -Path $Root -ChildPath $instance
            $files = @()
            if (Test-Path -Path $folder) {
                $files = @(Get-ChildItem -Path $folder -Recurse -File -Include *.bak, *.trn)
            }
            $total += $files.Count
            [pscustomobject]@{
                Name      = $instance
                FileCount = $files.Count
                SizeMB    = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
            }
        }
    }
    end {
        Write-Verbose "$total backup files in all"
    }
}

function Remove-OldBackup {
    <#
    .SYNOPSIS
    Removes the backup files older than the retention, and returns the files it removed.

    .DESCRIPTION
    Finds the old backup files with Get-OldBackup, then removes them one by one, after asking
    ShouldProcess: -WhatIf lists them without removing anything, -Confirm asks for each file.
    Returns each removed file, for the log of the run.

    .EXAMPLE
    Remove-OldBackup -Path lab/backups -RetentionDays 28 -WhatIf

    .EXAMPLE
    Remove-OldBackup -Path lab/backups -RetentionDays 28
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        # The folder of the backups, searched recursively.
        [Parameter(Mandatory)]
        [string] $Path,

        # Files written more than this number of days before the reference date are removed.
        [Parameter(Mandatory)]
        [ValidateRange(1, 3650)]
        [int] $RetentionDays,

        # The moment the retention is computed from; now by default.
        [datetime] $ReferenceDate = (Get-Date)
    )
    $old = Get-OldBackup -Path $Path -RetentionDays $RetentionDays -ReferenceDate $ReferenceDate
    foreach ($file in $old) {
        $age = [int]($ReferenceDate - $file.LastWriteTime).TotalDays
        if ($PSCmdlet.ShouldProcess($file.FullName, "Remove backup file, $age days old")) {
            Remove-Item -LiteralPath $file.FullName -Confirm:$false
            $file
        }
    }
}
