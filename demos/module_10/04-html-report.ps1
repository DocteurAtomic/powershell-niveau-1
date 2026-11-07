# Module 10, clip 10.4: the HTML report.
# Run from the root of the clone, one command at a time at the console, after
# ./demos/module_10/00-setup.ps1. 05-morning-inventory.ps1 writes lab/morning-inventory.html:
# open it in a browser.

$sample = [pscustomobject]@{ Name = 'sql1'; Status = 'OK' }, [pscustomobject]@{ Name = 'compta01'; Status = 'Unreachable' }
$sample | ConvertTo-Html
$sample | ConvertTo-Html -Fragment
$sample | ConvertTo-Html -Fragment -PreContent '<h2>Instances</h2>'
($sample | ConvertTo-Html -Fragment) -replace '<td>Unreachable</td>', '<td class="bad">Unreachable</td>'

# The morning report, on the whole inventory.
./demos/module_10/05-morning-inventory.ps1
Get-Item -Path lab/morning-inventory.html | Select-Object -Property Name, Length
Select-String -Path lab/morning-inventory.html -Pattern 'class="bad"' | Select-Object -First 5 | ForEach-Object -Process { $_.Line }

# The answer, every morning: the same command, then the page in a browser.
./demos/module_10/05-morning-inventory.ps1
