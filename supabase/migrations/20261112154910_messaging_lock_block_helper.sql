-- Production migration 20261112154910 messaging_lock_block_helper: production's recorded SQL, verbatim.
-- Source: supabase_migrations.schema_migrations.statements (read-only, 2026-11-19).
-- md5 of the SQL below this 4-line header (no trailing newline): b8ddce80228b599e466f393e5d6d8045
-- Replaces part of former repo file 016; commented original: docs/legacy/migrations-pre-c1/20261112000016_messaging_no_contact.sql (C1, approved 2026-11-19).
revoke execute on function public.is_blocked_between(uuid, uuid) from authenticated;
