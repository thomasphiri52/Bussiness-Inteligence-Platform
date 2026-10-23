# V30 — AI Business Intelligence Assistant

## Included
- Adds a Business Intelligence Assistant section to the portfolio and navigation.
- Reads projects, tasks, invoices, payments and support tickets through the existing Supabase browser client.
- Answers common questions with deterministic summaries grounded in returned records.
- Shows which data sources loaded and labels totals as account-visible figures.
- Does not send business data to an external AI provider and does not require an AI API key.

## Setup
1. Deploy the updated `index.html` alongside the existing portfolio assets.
2. Configure the existing Supabase URL and public anon key in the portfolio settings.
3. Sign in and use Refresh data.
4. Confirm that row-level security is enabled and tested for `projects`, `tasks`, `invoices`, `payments`, and `support_tickets`. The browser UI is not a security boundary.
5. Ensure client roles cannot read other clients' or organisations' records. The assistant uses the records returned by Supabase and cannot compensate for overly permissive RLS.

## Limitations
This is a rule-based, data-grounded assistant, not a generative AI model. Some schema variations may cause an individual source to be unavailable; the UI reports the available sources. The finance summary is indicative and must be reconciled per invoice before accounting use. Forecasts and business decisions require validated data and review.
