# Module 2, clip 2.4: a script whose output mixes two kinds of objects.
# Run it as a whole: ./demos/module_02/05-mixed-output.ps1
# The first object fixes the columns of the table; the totals that follow have no Name,
# and their Length is the intrinsic Length of any object, 1.
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Select-Object -Property Name, Length
Get-ChildItem -Path lab/backups/sql1/Finance/FULL -Filter *.bak | Measure-Object -Property Length -Sum
