-- ============================================================================
-- SIM MADIN — PostgREST Schema Cache Reload
-- ============================================================================
-- Trigger PostgREST to reload its schema cache after adding new tables,
-- columns, FKs, or RLS policies. Without this, the REST API returns
-- PGRST200 "Could not find a relationship" errors for newly added FKs.
--
-- This migration is idempotent — NOTIFY can be run multiple times safely.
-- ============================================================================

NOTIFY pgrst, 'reload schema';

-- Verification:
--   SELECT count(*) FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
--   Expected: 34 tables
-- ============================================================================
