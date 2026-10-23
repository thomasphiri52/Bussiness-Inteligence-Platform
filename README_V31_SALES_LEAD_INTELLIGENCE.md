# V31 — Sales & Lead Intelligence

## Included
- Pipeline value and probability-weighted value estimates.
- Transparent rules-based lead priority score using stage, amount and expected-close date.
- Stage breakdown, suggested follow-up priorities and CSV export.
- Uses the existing V19 Supabase browser configuration and signed-in session.

## Setup
1. Extract the ZIP and deploy the updated `index.html` to your existing hosting provider.
2. Configure Supabase in the V19 backend section and sign in.
3. Apply the existing `supabase/schema.sql` and relevant access-control migrations.
4. Confirm `opportunities` has the columns `id`, `title`, `stage`, `amount`, `expected_close`, `created_at`, `client_id`, and `owner_id`.
5. Test with separate organisation users and verify the `opportunities` RLS policies before production use.

## Scoring notes
The priority score is a heuristic to help organise follow-ups; it is not a machine-learning model and does not guarantee conversion. Weighted pipeline uses stage-based default probabilities and should be calibrated with actual historical win rates. The current view displays values in ZAR; use it only where opportunity amounts are denominated in ZAR. No emails or automatic lead outreach are sent.
