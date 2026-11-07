# Exercise of module 4, solution.
# One object per owner of production instances, written to lab/production-owners.json.
# , @( ) keeps Instances an array when an owner has a single instance: without it, the
# JSON file holds a string for that owner, and an array for the others.
Import-Csv -Path data/instances.csv |
    Where-Object -Property Environment -eq -Value Production |
    Group-Object -Property Owner |
    Select-Object -Property @{ Name = 'Owner'; Expression = { $_.Name } },
        @{ Name = 'Instances'; Expression = { , @($_.Group.Name) } } |
    ConvertTo-Json |
    Set-Content -Path lab/production-owners.json
