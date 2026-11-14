-- =====================================================================
-- 022 · Purple Pro, step 1: professional profiles + plans
-- ---------------------------------------------------------------------
-- A professional page is a VIEW of the existing seller account, never a
-- second user system:
--   profiles.pro_mode      'professional' (LinkedIn-style) or
--                          'creative_space' (visual page; builder in step 3).
--                          null = no professional page yet.
--   profiles.pro_public    the owner's public/private switch for /pro/<username>.
--   profiles.cover_url     banner picture (listing-images/<uid>/profile/...).
--   profiles.skills / languages   short tags, searchable (GIN index).
--   profiles.plan / plan_expires_at   'free' or 'premium'. Only admins
--                          (or the SQL editor) can change these; is_premium()
--                          is what every Premium-only rule checks.
--   pro_entries            experience, education, certifications, achievements.
--
-- Rules enforced here (no website bug can skip them):
--   * Only a seller signed in with their 2FA code can change pro fields
--     or entries (same rule as listings).
--   * A professional page can only be public for an active seller.
--   * Phone numbers / "pay me outside" text is refused in skills, languages
--     and entries, like everywhere else people type.
--   * Entries are public only while the page is public and the account is
--     in good standing; owners always see their own.
--   * 25 entries per section, 20 skills, 10 languages.
-- =====================================================================

create type public.pro_mode as enum ('professional', 'creative_space');
create type public.pro_plan as enum ('free', 'premium');
create type public.pro_entry_kind as enum ('experience', 'education', 'certification', 'achievement');

-- Short tag lists: at most max_items, each 1..max_len characters, no duplicates.
create or replace function public.tags_ok(arr text[], max_items int, max_len int) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(cardinality(arr), 0) <= max_items
     and not exists (select 1 from unnest(coalesce(arr, '{}')) t where char_length(btrim(t)) not between 1 and max_len)
     and (select count(distinct lower(t)) from unnest(coalesce(arr, '{}')) t) = coalesce(cardinality(arr), 0);
$$;

alter table public.profiles
  add column pro_mode          public.pro_mode,
  add column pro_public        boolean not null default false,
  add column pro_published_at  timestamptz,
  add column cover_url         text check (char_length(cover_url) <= 500),
  add column skills            text[] not null default '{}' check (public.tags_ok(skills, 20, 40)),
  add column languages         text[] not null default '{}' check (public.tags_ok(languages, 10, 30)),
  add column plan              public.pro_plan not null default 'free',
  add column plan_expires_at   timestamptz;

create index profiles_skills on public.profiles using gin (skills);
create index profiles_pro_public on public.profiles (pro_published_at desc) where pro_public;

-- Premium = premium plan that hasn't run out. (Payments arrive in step 7;
-- until then an admin turns Premium on in the SQL editor.)
create or replace function public.is_premium(uid uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((
    select p.plan = 'premium' and (p.plan_expires_at is null or p.plan_expires_at > now())
    from public.profiles p where p.id = uid
  ), false);
$$;
grant execute on function public.is_premium(uuid) to anon, authenticated;

-- Is this person's professional page publicly visible?
create or replace function public.pro_page_public(uid uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((
    select p.pro_public and p.pro_mode is not null and p.role = 'seller'
    from public.profiles p where p.id = uid
  ), false) and public.account_ok(uid);
$$;
grant execute on function public.pro_page_public(uuid) to anon, authenticated;

-- ---------- Protect plan fields (extends the 009 + 011 trigger) -------
create or replace function public.protect_profile_fields() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if new.id              is distinct from old.id
    or new.role            is distinct from old.role
    or new.is_verified     is distinct from old.is_verified
    or new.referral_code   is distinct from old.referral_code
    or new.rating_avg      is distinct from old.rating_avg
    or new.rating_count    is distinct from old.rating_count
    or new.created_at      is distinct from old.created_at
    or new.account_status  is distinct from old.account_status
    or new.status_reason   is distinct from old.status_reason
    or new.suspended_until is distinct from old.suspended_until
    or new.deletion_requested_at is distinct from old.deletion_requested_at   -- from 011 (privacy)
    or new.deleted_at      is distinct from old.deleted_at
    or new.plan            is distinct from old.plan
    or new.plan_expires_at is distinct from old.plan_expires_at then
      raise exception 'You can''t change that part of your profile' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

-- ---------- Pro fields: 2FA sellers only, safe text, publish date -----
create or replace function public.guard_pro_fields() returns trigger
language plpgsql set search_path = '' as $$
declare changed boolean := new.pro_mode is distinct from old.pro_mode
                        or new.pro_public is distinct from old.pro_public
                        or new.cover_url is distinct from old.cover_url
                        or new.skills is distinct from old.skills
                        or new.languages is distinct from old.languages;
begin
  if changed and current_user in ('anon', 'authenticated') then
    if not public.can_post() then
      raise exception 'Sign in with your 2FA code to edit your professional page' using errcode = '42501';
    end if;
    if new.skills is distinct from old.skills or new.languages is distinct from old.languages then
      perform public.forbid_contact(array_to_string(new.skills || new.languages, ' '));
    end if;
    -- Covers must be one of our own uploads, in the owner's folder.
    if new.cover_url is distinct from old.cover_url and new.cover_url is not null
       and position(('/storage/v1/object/public/listing-images/' || new.id::text || '/profile/') in new.cover_url) = 0 then
      raise exception 'Upload the cover picture first' using errcode = '22023';
    end if;
  end if;

  -- Tidy tags whoever writes them.
  new.skills := coalesce((select array_agg(btrim(t)) from unnest(new.skills) t), '{}');
  new.languages := coalesce((select array_agg(btrim(t)) from unnest(new.languages) t), '{}');

  -- A page stops being public when the account is deleted or stops being a seller.
  if new.deleted_at is not null or new.role <> 'seller' then
    if new.pro_public and new.pro_public is distinct from old.pro_public then
      raise exception 'Set up your professional page before making it public' using errcode = '22023';
    end if;
    new.pro_public := false;
  elsif new.pro_public and new.pro_mode is null then
    raise exception 'Set up your professional page before making it public' using errcode = '22023';
  end if;
  if new.pro_public and not coalesce(old.pro_public, false) and new.pro_published_at is null then
    new.pro_published_at := now();
  end if;
  return new;
end $$;

create trigger profiles_guard_pro before update on public.profiles
  for each row execute function public.guard_pro_fields();

-- ---------- Experience, education, certifications, achievements -------
create table public.pro_entries (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references public.profiles(id) on delete cascade,
  kind          public.pro_entry_kind not null,
  title         text not null check (char_length(btrim(title)) between 1 and 120),   -- role / course / certificate / award
  organisation  text check (char_length(organisation) <= 120),                       -- company / school / issuer
  location      text check (char_length(location) <= 80),
  start_year    smallint check (start_year between 1950 and 2100),
  end_year      smallint check (end_year between 1950 and 2100),
  is_current    boolean not null default false,
  description   text check (char_length(description) <= 1000),
  position      smallint not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  check (end_year is null or start_year is null or end_year >= start_year),
  check (not (is_current and end_year is not null))
);
create index pro_entries_owner on public.pro_entries (owner_id, kind, position);
create trigger pro_entries_updated_at before update on public.pro_entries
  for each row execute function public.set_updated_at();

alter table public.pro_entries enable row level security;

create policy "Entries of public pro pages are public" on public.pro_entries
  for select to anon, authenticated using (public.pro_page_public(owner_id));
create policy "Owners see their own entries" on public.pro_entries
  for select to authenticated using (owner_id = (select auth.uid()));
create policy "Admins see all entries" on public.pro_entries
  for select to authenticated using ((select public.is_admin()));
create policy "2FA sellers add their own entries" on public.pro_entries
  for insert to authenticated with check (owner_id = (select auth.uid()) and (select public.can_post()) and public.account_ok(owner_id));
create policy "2FA sellers edit their own entries" on public.pro_entries
  for update to authenticated using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and (select public.can_post()) and public.account_ok(owner_id));
create policy "2FA sellers remove their own entries" on public.pro_entries
  for delete to authenticated using (owner_id = (select auth.uid()) and (select public.can_post()));
create policy "Admins remove any entry" on public.pro_entries
  for delete to authenticated using ((select public.is_admin()));

-- Not SECURITY DEFINER on purpose: it must see who is writing (current_user),
-- and the owner can always count their own entries under RLS.
create or replace function public.check_pro_entry() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') then
    if tg_op = 'UPDATE' and (new.owner_id is distinct from old.owner_id or new.kind is distinct from old.kind) then
      raise exception 'You can''t move an entry' using errcode = '42501';
    end if;
    if tg_op = 'INSERT' and (select count(*) from public.pro_entries e
                             where e.owner_id = new.owner_id and e.kind = new.kind) >= 25 then
      raise exception 'You can add up to 25 items in each section' using errcode = '54000';
    end if;
    perform public.forbid_contact(concat_ws(' ', new.title, new.organisation, new.location, new.description));
  end if;
  new.title := btrim(new.title);
  return new;
end $$;
create trigger pro_entries_check before insert or update on public.pro_entries
  for each row execute function public.check_pro_entry();
revoke execute on function public.check_pro_entry(), public.guard_pro_fields() from public, anon, authenticated;

-- ---------- Data export: include the professional page -----------------
do $$
declare d text;
begin
  d := pg_get_functiondef('public.export_my_data()'::regprocedure);
  d := replace(d, '''security_events_about_you'',',
    '''professional_page'', (select jsonb_build_object(''type'', p.pro_mode, ''public'', p.pro_public,
                               ''skills'', p.skills, ''languages'', p.languages, ''cover'', p.cover_url,
                               ''plan'', p.plan, ''plan_expires_at'', p.plan_expires_at,
                               ''entries'', coalesce((select jsonb_agg(to_jsonb(e) - ''owner_id'' order by e.kind, e.position)
                                                      from public.pro_entries e where e.owner_id = uid), ''[]''))
                             from public.profiles p where p.id = uid),
    ''security_events_about_you'',');
  execute d;
end $$;
