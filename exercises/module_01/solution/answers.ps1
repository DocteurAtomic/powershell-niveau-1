# Exercise of module 1, solution.
# Get-Command -Noun Date lists Get-Date and Set-Date; Get-Help -Name Get-Date gives its synopsis.
Get-Date
# Get-Command -Noun Path lists Convert-Path, Join-Path, Resolve-Path, Split-Path and Test-Path;
# Get-Help -Name Resolve-Path -Parameter Path shows that -Path takes the path to resolve.
Resolve-Path -Path data/instances.csv
