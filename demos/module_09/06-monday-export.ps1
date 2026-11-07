# Module 9, clip 9.5: the export for the accounting department.
# Run from the root of the clone, one command at a time at the console. The secret sql-lab of
# clip 9.1 must exist (or run ./demos/module_09/00-setup.ps1). The video writes the list for
# Monday 2 November 2026; for your own list, leave out -ReferenceDate, which is today.

$cred = Get-Secret -Name sql-lab
$sql1 = 'localhost,14533'
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

# Export-Csv writes numbers and dates for the culture of the session: here, en-US.
$query = 'SELECT InvoiceCode, InvoiceDate, GrossAmount FROM Enrollment.Invoice WHERE InvoiceCode = @Code;'
$invoice = Invoke-DbaQuery -SqlInstance $sql1 -SqlCredential $cred -Database PachadataTraining -Query $query -SqlParameter @{ Code = 'FA2026-006814' } -As PSObject
$invoice | ConvertTo-Csv -Delimiter ';'
$invoice | ConvertTo-Csv -UseCulture
(Get-Culture).Name
(Get-Culture).TextInfo.ListSeparator
$invoice | ConvertTo-Csv -UseCulture -Delimiter ';'

# Under a French culture, the separator, the dates and the decimals change.
[cultureinfo]::CurrentCulture = 'fr-FR'
$invoice | ConvertTo-Csv -UseCulture
[cultureinfo]::CurrentCulture = 'en-US'

# The list of the accounting department, for Monday 2 November 2026.
./demos/module_09/05-unpaid-invoices.ps1 -ReferenceDate 2026-11-02 -Verbose
Get-Content -Path lab/unpaid-invoices.csv -TotalCount 4

# The same list, for another Monday.
./demos/module_09/05-unpaid-invoices.ps1 -ReferenceDate 2026-10-05 -Path lab/unpaid-2026-10-05.csv
Get-Content -Path lab/unpaid-2026-10-05.csv -TotalCount 2
Remove-Item -Path lab/unpaid-invoices.csv, lab/unpaid-2026-10-05.csv
