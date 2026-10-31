# Solution of the exercise of module 2, part 2.
Get-ChildItem -Path $PSHOME -File |
    Group-Object -Property Extension -NoElement |
    Sort-Object -Property Count -Descending
