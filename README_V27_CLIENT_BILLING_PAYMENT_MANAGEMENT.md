# V27 — Client Billing & Payment Management

## Included
- Invoice creation form with invoice number, amount, currency, optional client/project IDs, due date and draft/sent status.
- Payment recording for an existing invoice, including paid date and reference.
- Invoice register with calculated recorded payments and remaining balances.
- Print / Save as PDF invoice copy and CSV export.
- Supabase connection reuses the V19 browser configuration (`tp_v19_supabase_config_v1`).
- SQL index migration: `supabase/v27_billing_payment_management.sql`.

## Setup
1. Back up the project and test against a non-production Supabase environment.
2. Review and apply `supabase/v27_billing_payment_management.sql` in Supabase SQL Editor.
3. Confirm the V19 schema and current RLS policies are installed. Verify policies for `invoices` and `payments` enforce organisation boundaries and staff roles for INSERT/UPDATE. The frontend role check is not a substitute for RLS.
4. Sign in with a profile that has an `organisation_id`. Admin and project_manager roles see write forms; all actual writes remain subject to database policies.
5. Use real payment entries only after confirming funds received. This is a ledger-entry feature, not a payment gateway; no card/bank collection is performed.

## Important controls / known limitations
- Optional client/project fields expect valid UUIDs. The UI leaves them optional to avoid assuming a client-picker schema.
- The invoice print view is a generated copy, not a tax-compliance certificate and not proof of payment.
- The current frontend records payment rows and attempts to mark invoices paid when recorded totals reach the invoice amount. For production, move this operation into a database transaction or server-side RPC so concurrent entries cannot cause inconsistent invoice status.
- Confirm all payment/invoice queries and writes are covered by tenant-aware RLS. Do not rely on hidden UI controls as access control.
- Refunds, reversals, tax calculations, PDF archival, gateway integrations, and automatic receipts are not included.
