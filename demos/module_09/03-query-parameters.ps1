# Module 9, clip 9.3: a query with parameters, and the injection that a built string allows.
# Run from the root of the clone, one command at a time at the console. The secret sql-lab of
# clip 9.1 must exist (or run ./demos/module_09/00-setup.ps1).

$cred = Get-Secret -Name sql-lab
$sql1 = 'localhost,14533'
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

# One invoice, the value passed as a parameter, @Code, never pasted into the text.
$query = 'SELECT InvoiceCode, InvoiceDate, DueDate, GrossAmount FROM Enrollment.Invoice WHERE InvoiceCode = @Code;'
Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Database PachadataTraining -Query $query -SqlParameter @{ Code = 'FA2026-006814' }

# The same query built by concatenation: the value becomes SQL code.
$code = 'FA2026-006814'
"SELECT COUNT(*) AS Invoices FROM Enrollment.Invoice WHERE InvoiceCode = '$code';"
$code = "x' OR 1 = 1 --"
$text = "SELECT COUNT(*) AS Invoices FROM Enrollment.Invoice WHERE InvoiceCode = '$code';"
$text
Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Database PachadataTraining -Query $text

# The same value as a parameter is only a value: no invoice has that code.
$count = 'SELECT COUNT(*) AS Invoices FROM Enrollment.Invoice WHERE InvoiceCode = @Code;'
Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Database PachadataTraining -Query $count -SqlParameter @{ Code = $code }

# Several parameters, a date and a number, in one hash table.
$late = @'
SELECT COUNT(*) AS Invoices
FROM Enrollment.Invoice
WHERE DocumentType = 'I'
  AND DueDate < DATEADD(day, -@Days, @ReferenceDate);
'@
$parameters = @{ ReferenceDate = Get-Date -Date '2026-11-02'; Days = 30 }
Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Database PachadataTraining -Query $late -SqlParameter $parameters
