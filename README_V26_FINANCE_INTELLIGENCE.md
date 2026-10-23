# V26 — Finance Intelligence & Revenue Forecasting

## What is added
- Finance dashboard reads invoices and payments visible to the signed-in user through Supabase RLS.
- Currency-aware invoice, payment, outstanding-balance and overdue breakdowns. Currency values are not combined across currencies.
- Invoice register showing amount, recorded payments, estimated remaining balance and due date.
- Six-month recorded-collection trend and a clearly labelled directional estimate based on months with recorded data.
- CSV export of visible invoice and payment rows. The dashboard does not create, update or delete financial transactions.
- Optional V26 SQL indexes to support common finance queries without changing access policies.

## Setup
1. Back up your database and apply `supabase/v26_finance_intelligence.sql` in staging after review.
2. Confirm invoices and payments have correct organisation-scoped RLS policies. The browser uses the existing V19 Supabase URL and public anon key configuration and requires a signed-in account.
3. Open V26 Finance Intelligence and choose Refresh finance data.
4. Test using non-production data, including multiple currencies, partial payments, failed payments, overdue invoices and cross-organisation accounts.

## Calculation notes and limitations
- Outstanding is invoice amount minus payments whose status is not `failed`, floored at zero. Draft and void invoices are excluded from the headline outstanding summary. Payment status semantics should be aligned with your payment provider before production use.
- The overdue count checks due date, status and calculated balance; validate how your business marks paid/void invoices.
- The monthly trend sums successful/non-failed dated payments across currencies but labels the chart in ZAR. If your organisation uses multiple currencies, treat this chart as indicative only; for production reporting, group the trend by currency or normalise using dated FX rates.
- The next-month figure is a simple average of months with recorded payments in the six-month window, not an accounting forecast or guarantee.
- CSV export contains financial data; store it securely and share it only with authorised recipients.
- This upgrade is not a bookkeeping, tax, audit or regulatory compliance certification. Verify calculations with a qualified finance professional before relying on them for decisions.
