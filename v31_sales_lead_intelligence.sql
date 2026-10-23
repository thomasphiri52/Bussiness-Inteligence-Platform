-- V31: query-performance indexes for sales intelligence.
-- Existing RLS policies remain the security boundary; review them before deployment.
create index if not exists opportunities_org_created_idx
  on public.opportunities (organisation_id, created_at desc);
create index if not exists opportunities_org_stage_idx
  on public.opportunities (organisation_id, stage);
create index if not exists opportunities_org_close_idx
  on public.opportunities (organisation_id, expected_close);
