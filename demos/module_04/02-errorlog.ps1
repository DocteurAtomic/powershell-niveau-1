# Module 4, clip 4.2: the failed logins of the SQL Server error logs, per account.
# Run from the root of the clone, one command at a time at the console.

# A text file is read as an array of strings, one per line.
Get-ChildItem -Path data/errorlog
$lines = Get-Content -Path data/errorlog/errorlog.1
$lines.Count
$lines[0].GetType().FullName
Get-Content -Path data/errorlog/errorlog.1 -Tail 3

# Select-String returns a MatchInfo object for each line that matches.
Select-String -Path data/errorlog/errorlog.3 -Pattern 'Login failed'
$failed = Select-String -Path data/errorlog/* -Pattern 'Login failed'
$failed.Count
$failed[0] | Get-Member -MemberType Property
$failed[0] | Select-Object -Property Filename, LineNumber, Line

# A capture group takes the account out of the line.
$accounts = Select-String -Path data/errorlog/* -Pattern 'Login failed for user ''(\w+)'''
$accounts[0].Matches[0].Groups | Select-Object -Property Name, Value
$accounts[0].Matches[0].Groups[1].Value
$accounts |
    Group-Object -Property { $_.Matches[0].Groups[1].Value } -NoElement |
    Sort-Object -Property Count -Descending
