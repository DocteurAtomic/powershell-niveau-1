# Module 9, clip 9.4: the types that come back from SQL Server, DataRow and DBNull.
# Run from the root of the clone, one command at a time at the console. The secret sql-lab of
# clip 9.1 must exist (or run ./demos/module_09/00-setup.ps1).

$cred = Get-Secret -Name sql-lab
$sql1 = 'localhost,14533'
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

# An invoice that nobody has paid: its last payment date is NULL.
$query = @'
SELECT i.InvoiceCode, i.GrossAmount, i.InvoiceDate,
       (SELECT MAX(p.PaymentDate) FROM Enrollment.Payment AS p
        WHERE p.InvoiceCode = i.InvoiceCode) AS LastPaymentDate
FROM Enrollment.Invoice AS i
WHERE i.InvoiceCode = @Code;
'@
$row = Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Database PachadataTraining -Query $query -SqlParameter @{ Code = 'FA2026-006814' }
$row
$row.GetType().FullName
$row | Get-Member -MemberType Property

# By default, NULL comes back as DBNull, which is not $null, and which converts to $true.
$row.LastPaymentDate -eq $null
$row.LastPaymentDate.GetType().FullName
[bool] $row.LastPaymentDate
$row | Select-Object -Property *

# With -As PSObject: a PSCustomObject, $null for NULL, decimal and datetime for the rest.
$row = Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Database PachadataTraining -Query $query -SqlParameter @{ Code = 'FA2026-006814' } -As PSObject
$row.GetType().FullName
$row.LastPaymentDate -eq $null
[bool] $row.LastPaymentDate
$row.GrossAmount.GetType().FullName
$row.InvoiceDate.GetType().FullName
$row.InvoiceDate.AddDays(30)
