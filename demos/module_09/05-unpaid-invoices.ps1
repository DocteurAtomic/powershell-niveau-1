<#
.SYNOPSIS
Exports the invoices that are not settled more than 30 days after their due date.

.DESCRIPTION
The weekly list of the accounting department. Reads the login of the lab in the vault
PachaOps (secret sql-lab, clip 9.1), runs a query with parameters on PachadataTraining, and
writes one line per invoice whose due date is more than Days days before ReferenceDate and
whose payments, up to ReferenceDate, do not cover the amount.

The file is a CSV separated by semicolons, in UTF-8 with a byte order mark, with dates and
amounts written for Culture (French by default), so that a French spreadsheet reads them as
dates and numbers, whatever the culture of the session that runs the script. Returns one
object that says how many invoices were written, their total and the file. Module 9 of the
course.

.EXAMPLE
./demos/module_09/05-unpaid-invoices.ps1 -ReferenceDate 2026-11-02

.EXAMPLE
./demos/module_09/05-unpaid-invoices.ps1 -ReferenceDate 2026-10-05 -Path lab/unpaid-2026-10-05.csv
#>
[CmdletBinding()]
param(
    # The day the list is written for; today by default.
    [datetime] $ReferenceDate = (Get-Date).Date,

    # How many days past its due date an unpaid invoice must be to appear in the list.
    [int] $Days = 30,

    # The CSV file to write.
    [string] $Path = 'lab/unpaid-invoices.csv',

    # The instance that holds PachadataTraining.
    [string] $SqlInstance = 'localhost,14533',

    # The culture of the spreadsheet that opens the file.
    [cultureinfo] $Culture = 'fr-FR'
)
$ErrorActionPreference = 'Stop'

$cred = Get-Secret -Name sql-lab -Vault PachaOps
Set-DbatoolsInsecureConnection -SessionOnly | Out-Null

$query = @'
SELECT i.InvoiceCode,
       COALESCE(co.Name, CONCAT(c.FirstName, ' ', c.LastName)) AS Customer,
       i.InvoiceDate,
       i.DueDate,
       DATEDIFF(day, i.DueDate, @ReferenceDate) AS DaysOverdue,
       i.GrossAmount - COALESCE(p.Paid, 0) AS AmountDue,
       p.LastPaymentDate
FROM Enrollment.Invoice AS i
LEFT JOIN Contact.Company AS co ON co.CompanyId = i.CompanyId
LEFT JOIN Contact.Contact AS c ON c.ContactId = i.ContactId
OUTER APPLY (SELECT SUM(pay.Amount) AS Paid, MAX(pay.PaymentDate) AS LastPaymentDate
             FROM Enrollment.Payment AS pay
             WHERE pay.InvoiceCode = i.InvoiceCode
               AND pay.PaymentDate <= @ReferenceDate) AS p
WHERE i.DocumentType = 'I'
  AND i.DueDate < DATEADD(day, -@Days, @ReferenceDate)
  AND i.GrossAmount > COALESCE(p.Paid, 0)
ORDER BY i.DueDate DESC, i.InvoiceCode;
'@
$parameters = @{ ReferenceDate = $ReferenceDate; Days = $Days }
$invoices = Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $cred -Database PachadataTraining `
    -Query $query -SqlParameter $parameters -As PSObject
Write-Verbose -Message "$(@($invoices).Count) unpaid invoices on $($ReferenceDate.ToString('yyyy-MM-dd'))."

# Dates and amounts as the spreadsheet of the accounting department expects them.
$lines = foreach ($invoice in $invoices) {
    [pscustomobject]@{
        InvoiceCode     = $invoice.InvoiceCode
        Customer        = $invoice.Customer
        InvoiceDate     = $invoice.InvoiceDate.ToString('d', $Culture)
        DueDate         = $invoice.DueDate.ToString('d', $Culture)
        DaysOverdue     = $invoice.DaysOverdue
        AmountDue       = $invoice.AmountDue.ToString('F2', $Culture)
        LastPaymentDate = if ($null -eq $invoice.LastPaymentDate) { '' } else { $invoice.LastPaymentDate.ToString('d', $Culture) }
    }
}
$lines | Export-Csv -Path $Path -Delimiter ';' -Encoding utf8BOM

[pscustomobject]@{
    ReferenceDate = $ReferenceDate.ToString('yyyy-MM-dd')
    Invoices      = @($invoices).Count
    AmountDue     = ($invoices | Measure-Object -Property AmountDue -Sum).Sum
    Path          = $Path
}
