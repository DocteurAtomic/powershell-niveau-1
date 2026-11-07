# Module 4, clip 4.4: objects to JSON and back, the depth, and a settings file.
# Run from the root of the clone, one command at a time at the console.

# The failed logins per account, as objects, then as JSON.
$failures = Select-String -Path data/errorlog/* -Pattern 'Login failed for user ''(\w+)''' |
    Group-Object -Property { $_.Matches[0].Groups[1].Value } -NoElement |
    Sort-Object -Property Count -Descending |
    Select-Object -Property @{ Name = 'Account'; Expression = { $_.Name } },
        @{ Name = 'Failures'; Expression = { $_.Count } }
$failures | ConvertTo-Json
$failures | ConvertTo-Json | Set-Content -Path lab/failed-logins.json
$read = Get-Content -Path lab/failed-logins.json -Raw | ConvertFrom-Json
$read
$read | Get-Member -MemberType NoteProperty
Remove-Item -Path lab/failed-logins.json

# Beyond two levels, ConvertTo-Json writes a string and warns.
$report = [pscustomobject]@{
    Instance  = 'sql1'
    Databases = @(
        [pscustomobject]@{ Name = 'Finance'; Backups = @([pscustomobject]@{ Type = 'FULL'; Files = 6 }) }
    )
}
$report | ConvertTo-Json
$report | ConvertTo-Json -Depth 4

# The settings of the weekly report, read from a JSON file.
Get-Content -Path demos/module_04/weekly-report.json
$config = Get-Content -Path demos/module_04/weekly-report.json -Raw | ConvertFrom-Json
$config
$config.Export.Delimiter
