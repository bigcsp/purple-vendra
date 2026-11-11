-- =====================================================================
-- Purple Vendra — backend step 4: file storage + ID verification
-- (9 Nov 2026)
--
-- * Two storage buckets:
--     listing-images  PUBLIC   photos shown on listings (5 MB, jpg/png/webp)
--     id-documents    PRIVATE  seller ID documents (5 MB, jpg/png/webp/pdf)
-- * Files live in a folder named after the owner's user id:
--     listing-images/<user id>/<listing id>/<file>
--     id-documents/<user id>/<file>
--   so nobody can upload into, or overwrite, someone else's folder.
-- * Only sellers signed in with 2FA can upload (same rule as posting).
-- * ID documents: only the seller and admins can see them; sellers can't
--   delete or replace a submitted file (kept as evidence).
-- * Verification: sellers submit, admins approve or reject. Nobody can
--   approve themselves. Approval turns on the "verified" badge.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Buckets
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('listing-images', 'listing-images', true,  5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('id-documents',   'id-documents',   false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do update set
  public             = excluded.public,
  file_size_limit    = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------
-- Storage rules: listing photos
-- (Public bucket: anyone can VIEW a photo by its link without a rule.)
-- ---------------------------------------------------------------------
create policy "Sellers upload listing photos to their own folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.can_post())
  );

create policy "Sellers see their own listing photo files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Sellers replace their own listing photos"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.can_post())
  );

create policy "Sellers delete their own listing photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.can_post())
  );

-- ---------------------------------------------------------------------
-- Storage rules: ID documents (private)
-- ---------------------------------------------------------------------
create policy "Sellers upload their ID to their own folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'id-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.can_post())
  );

create policy "Sellers see their own ID documents"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'id-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Admins see all ID documents"
  on storage.objects for select to authenticated
  using (bucket_id = 'id-documents' and (select public.is_admin()));

-- ---------------------------------------------------------------------
-- Seller verification
-- ---------------------------------------------------------------------
alter table public.seller_verifications
  add column if not exists id_type text
    check (id_type in ('nin', 'drivers_licence', 'international_passport', 'voters_card'));

-- Sellers can submit and resubmit; only admins can approve or reject.
create or replace function public.protect_seller_verification() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') and not public.is_admin() then
    if tg_op = 'UPDATE' and old.status = 'approved' then
      raise exception 'Your ID is already verified. Contact support to change it.' using errcode = '42501';
    end if;
    if new.user_id is distinct from auth.uid() then
      raise exception 'You can only submit your own verification' using errcode = '42501';
    end if;
    if new.id_document_path is null
       or new.id_document_path not like (auth.uid()::text || '/%') then
      raise exception 'Upload your ID document first' using errcode = '42501';
    end if;
    -- Every (re)submission goes back to the queue for review.
    new.status                 := 'pending';
    new.rejection_reason       := null;
    new.reviewed_by            := null;
    new.reviewed_at            := null;
    new.payment_recipient_code := case when tg_op = 'UPDATE' then old.payment_recipient_code end;
    new.submitted_at           := now();
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status
        and new.status in ('approved', 'rejected') then
    -- Admin decision: record who and when.
    new.reviewed_by := coalesce(new.reviewed_by, auth.uid());
    new.reviewed_at := now();
  end if;
  return new;
end $$;

drop trigger if exists seller_verifications_protect on public.seller_verifications;
create trigger seller_verifications_protect
  before insert or update on public.seller_verifications
  for each row execute function public.protect_seller_verification();

-- Keep the public "verified" badge in step with the verification status.
create or replace function public.sync_verified_badge() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.profiles
  set is_verified = (new.status = 'approved')
  where id = new.user_id and is_verified is distinct from (new.status = 'approved');
  return null;
end $$;

drop trigger if exists seller_verifications_badge on public.seller_verifications;
create trigger seller_verifications_badge
  after insert or update of status on public.seller_verifications
  for each row execute function public.sync_verified_badge();

revoke execute on function public.sync_verified_badge() from public, anon, authenticated;

create policy "Sellers can submit their verification"
  on public.seller_verifications for insert to authenticated
  with check (user_id = (select auth.uid()) and (select public.can_post()));

create policy "Sellers can resubmit their verification"
  on public.seller_verifications for update to authenticated
  using (user_id = (select auth.uid()) and (select public.can_post()))
  with check (user_id = (select auth.uid()));

create policy "Admins can review verifications"
  on public.seller_verifications for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- ---------------------------------------------------------------------
-- Listing photos table (the 2FA restrictive rules were added in 006)
-- ---------------------------------------------------------------------
alter table public.listing_images
  add constraint listing_images_max_10 check (position between 0 and 9);

create policy "Photos of approved listings are public"
  on public.listing_images for select to anon, authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.status = 'approved'
  ));

create policy "Sellers see photos of their own listings"
  on public.listing_images for select to authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = (select auth.uid())
  ));

create policy "Sellers add photos to their own listings"
  on public.listing_images for insert to authenticated
  with check (
    storage_path like ((select auth.uid())::text || '/%')
    and exists (
      select 1 from public.listings l
      where l.id = listing_id and l.seller_id = (select auth.uid())
    )
  );

create policy "Sellers reorder photos of their own listings"
  on public.listing_images for update to authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = (select auth.uid())
  ))
  with check (storage_path like ((select auth.uid())::text || '/%'));

create policy "Sellers remove photos from their own listings"
  on public.listing_images for delete to authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = (select auth.uid())
  ));

create policy "Admins manage all listing photos"
  on public.listing_images for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
