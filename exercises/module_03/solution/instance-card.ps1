# Solution of the exercise of module 3, part 2.
$sqlInstance = 'compta01.pachadata.example,1433'
[pscustomobject]@{
    Name        = 'compta01'
    SqlInstance = $sqlInstance
    Port        = [int]($sqlInstance -split ',')[1]
    Environment = 'Production'
    Owner       = 'finance'
}
