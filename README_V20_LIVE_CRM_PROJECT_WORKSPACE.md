# V20 — Live CRM & Project Workspace

This release adds a Supabase-backed workspace to the portfolio for clients, opportunities, projects, milestones and tasks.

## Included
- Create clients and opportunities
- Create projects, milestones and tasks
- Load up to 100 recent rows per supported table, subject to Supabase Row Level Security
- Update task status
- Export currently loaded records to CSV
- Summary counts for clients, opportunities, projects and open tasks
- Reuses V19 Supabase connection and authenticated session

## Setup
1. Deploy the portfolio to a host that serves `index.html` and the `supabase/` folder.
2. Create a Supabase project and run `supabase/schema.sql` in the SQL editor.
3. Enable email/password authentication and configure allowed redirect URLs.
4. In V19, enter the Supabase project URL and public anon/publishable key, then connect and sign in.
5. Provision an organisation and assign the signed-in profile's `organisation_id` to that organisation. Set an appropriate role through a trusted administrator process.
6. Open V20 and refresh live data.

## Important limitations
- V20 does not provision organisations, elevate roles, or invite staff.
- A new profile has no organisation assigned by default, so a trusted setup step is required before business records can be created.
- All data access still depends on correct database RLS policies. The included V19 schema is a starter implementation and needs security review and testing before real customer data is used.
- The browser stores the public Supabase URL and public key in local storage. Never place a service-role/secret key in the browser.
- Export includes only records the current signed-in session is permitted to read and that were loaded into the page.
