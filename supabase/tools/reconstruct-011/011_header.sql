-- =====================================================================
-- 011 · Privacy & data rights  (RECONSTRUCTED, Phase 1b W3, 2026-11-16)
-- ---------------------------------------------------------------------
-- The original 011 file was run by hand in the production SQL editor on
-- ~9-10 Nov 2026 and never committed. This file was rebuilt from the
-- production catalog (read-only capture, docs/schema/) so that a clean
-- database built from the repo matches production.
--
-- Where a later migration patches one of these functions by text
-- replacement (012, 016, 021, 022), this file contains the version
-- BEFORE those patches, so replaying 001→022 ends in production's state.
--
-- NEVER run this on production: production already has these objects.
-- Production history will only record it via `migration repair` (P1).
--
-- Contents
--   * pg_cron + pg_net extensions (012 uses cron.schedule; cleanup uses net.http_post)
--   * profiles.deletion_requested_at / deleted_at
--   * seller_verifications.id_document_deleted_at
--   * storage_deletion_queue (RLS on, no policies: service role only)
--   * queue_file_deletion, process_account_deletion, request_account_deletion,
--     cancel_account_deletion, export_my_data, run_privacy_retention
--   * cron: privacy-retention (02:15 daily), storage-cleanup (02:45 daily)
--
-- Environment requirement: Vault secret `project_url`
-- (e.g. https://<ref>.supabase.co) must exist before this runs, so the
-- storage-cleanup cron job calls THIS project's Edge Function. If it is
-- missing, the local Supabase URL is used (CI / local only).
-- =====================================================================

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- ---------- Columns ----------------------------------------------------
alter table public.profiles
  add column if not exists deletion_requested_at timestamptz,
  add column if not exists deleted_at timestamptz;
alter table public.seller_verifications
  add column if not exists id_document_deleted_at timestamptz;

-- ---------- Storage deletion queue ------------------------------------
-- Files can only be deleted through the Storage API, so the database
-- queues them and the storage-cleanup Edge Function deletes them nightly.
create table public.storage_deletion_queue (
  id          bigint generated always as identity primary key,
  bucket_id   text not null,
  object_name text not null,
  reason      text not null,
  queued_at   timestamptz not null default now(),
  done_at     timestamptz,
  last_error  text,
  unique (bucket_id, object_name)
);
alter table public.storage_deletion_queue enable row level security;

-- ---------- Functions --------------------------------------------------
