# Solution of the exercise of module 2, part 1.
Get-ChildItem -Path $PSHOME -File |
    Sort-Object -Property Length -Descending |
    Select-Object -First 5 -Property Name, @{ Name = 'SizeKB'; Expression = { [math]::Round($_.Length / 1KB) } }
