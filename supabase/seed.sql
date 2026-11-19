-- =====================================================================
-- Purple Shop synthetic seed. GENERATED FILE: do not edit by hand.
-- Source: supabase/tools/seed/generate_seed.py (run it to regenerate).
-- Every name, message and figure below is invented. Staging and local only.
-- Docs: docs/W6-SEED-AND-ANONYMIZER.md
--
-- ONE statement (a single DO block): it completes fully or changes nothing,
-- in psql autocommit, the Supabase CLI and the SQL editor alike.
-- Before running, name the target (it must match this database's Vault project_url):
--   staging:  set purple.seed_target = 'fwyviexwregngnqtwcra';
--   local:    set purple.seed_target = 'local';   (project_url must be a local address)
-- Optional test password for the non-admin accounts: set purple.seed_password = '...';
-- Generator w6-2, body digest b10f52cb983e10727e8726c6d62cf9dcb19012afa985c8409a39a960a8cea4ee
-- =====================================================================
do $seed$
declare
  c_prod_ref     constant text   := 'nozxxxldfthbwhjwbsmy';
  c_staging_refs constant text[] := array['fwyviexwregngnqtwcra'];
  c_seed_ids     constant uuid[] := array[
    '003357a5-0cd9-62bf-8fa2-3677d1a2e305', '00adace5-bdef-c38a-7a30-88ce888199f0', '015b4863-6fab-ffa8-9f8e-fb119a7d1e93', '02b44300-ef13-5b46-fd6a-3c339e5894c6',
    '04018815-e62f-a9c1-88e5-11262d35745e', '0582abed-d729-a640-5f32-83261d87f537', '065cae22-135c-dc6a-d539-8cfc70565d94', '075f9a3f-cd53-fb89-2ffb-a4244f986e29',
    '078cf7cd-d43e-8909-4e82-3a8f54700ba4', '090a9bd4-17d3-fa68-1adc-103a5c945a46', '09251ec4-ea6f-71f0-0105-e0ade86d2a5c', '09d5527a-2441-3f85-96de-2f17db71932f',
    '0a3e16d4-1d07-f3be-5434-961d501dc9ee', '0b247d05-4c2d-3855-10ca-1ac40c298aca', '0c2aad9d-7eae-3d0e-a0ea-ca9cd49d9cd1', '0c80ebfd-d5c0-1f0a-016b-0d608df1b1cb',
    '0d0ecce9-349e-cad5-466f-86303451bd9d', '0f89d922-f179-c83a-4035-7269ab41815d', '11f5207d-0463-a1ea-6bc9-aa8657d7c229', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8',
    '120f4191-4f6e-6fb0-81e8-6ef84a7b5c4f', '126e3b70-3dca-de40-d3d8-d75390ced01e', '12ceebdd-b119-5538-503c-92f48de35403', '131732fb-08c1-032f-23e3-6d0f8e8e9bfa',
    '13ab1241-58ee-bf89-ae2f-88f234cd0c57', '1552c7e1-cc9c-93b7-ba81-3020842f3191', '15a8f5b3-550f-c875-5a5d-2c21b85efc2b', '15c2b231-cbe8-54e6-3be2-b07b3dc082b1',
    '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', '19d2c070-1501-1c48-da57-d74352bbde02', '1e02abfd-f439-d9d0-c0ff-59c9f27d561e', '1ea3ff05-64db-3f7d-270c-dd9a89ba7575',
    '1fdc6d36-b19f-d52d-b523-1776acb60e9b', '215e4877-dfee-a9c4-0130-ee761894e3fa', '219bd8b4-9895-fb9a-90a1-a972b3708646', '2381aaca-e01f-c9ce-1643-7e90f0874e2e',
    '29a9b6de-a3d4-daf0-2daa-d1da95150e9c', '2b7d6168-fb32-2091-6848-977c9ebe9666', '2d943e05-e848-04f1-d459-b9fb6a38ac33', '2dd9b235-09c0-aae4-9e2e-f6ef8195ae9c',
    '2e459972-82bb-edae-74c7-a0bede719812', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '3017a650-3ea5-db08-cd17-5be73045c65b', '3022de0b-4a28-5e57-1148-55296124fb25',
    '308e17ed-c01c-8927-176a-4ba0c35f226a', '31c9221a-f6c1-4d62-2310-31a3cc25e981', '34caa851-e5d7-e63a-f896-430ba2773cc2', '3539bf74-47b4-66b3-57f2-c87b68f738dc',
    '37bc139a-5476-734d-b327-e836aaf415dc', '3850c6d8-9934-1f10-5264-6740dff2d7d6', '388fc4c1-d047-6efc-6d86-abdc0435b188', '3c06cb94-7d97-8145-a1d2-ff3eafeced3a',
    '3df0b38d-cf33-81d9-18d1-2e37f58fecfc', '3e71c61d-8671-860d-a453-b178abaa1bd4', '3f114935-49c3-6dc9-e0f8-494e9bfe0593', '3fd6c6ea-9c39-f1cb-ca73-42382088c2b4',
    '3ffa35bd-37c2-f7ad-eba7-e8e007f4da96', '40218982-dc78-2797-e92d-f933c000185f', '42162694-eb15-32c4-2179-0e771c425a61', '42a7e888-7714-9b34-dfa8-f08a903b1d6a',
    '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', '43d7ad89-30aa-6ad0-4b1e-6c959f0aea55', '44507445-63e5-9b3a-b501-6faf997ddcde', '4488d9f0-6c5d-c839-48e8-092ea18739d4',
    '450083a5-e4c8-18ab-653f-e3d592ee2080', '45c7755d-a781-7208-e8e0-86e9f92dad7b', '486236f3-6bd2-21b0-d98f-a0b96145eddd', '4b22aea3-de1f-b594-ff96-e2c297057b1b',
    '4cb2e1aa-b6fa-a2e1-c746-e7a2a97f7540', '4d0ada2d-857d-31f8-19e6-231857e02dd5', '5364cec5-4b93-658a-9fe9-c5f618689935', '55e9eb9b-a001-2700-706b-4ec3a406e4f3',
    '585e6a19-7bc6-e7e3-c17d-6d9d4e6af849', '58ddcb65-10ac-4b78-dbea-3e221122aa52', '5a8ae12d-45e5-5b02-4ed0-5f6a41264170', '5b685f38-9471-8789-5ba8-9609f1ee3484',
    '5bc541dd-6d66-1b2e-f2be-1fb6e7ba6c2c', '5c97a49e-c020-cf45-16e3-0b92f821db32', '5d9ca47d-593a-2ab2-1862-740d33c9f812', '5dd229ee-4840-ce1f-fb95-c9e949052242',
    '5f1842b5-ea5e-2002-e0c4-98763a25242d', '5faf9c50-0ffa-7098-bb94-0507380c1764', '5fee9486-beac-b161-c9c4-a6ab8f556b98', '65003b04-4337-0ee0-54a7-8af5dc80cbdf',
    '65211882-92ed-eaf7-e64e-1f7ccd7f9574', '658f85be-790d-4fde-d060-ba0074be15df', '66ec67a5-8850-5fad-e3d9-a2b2d4a61814', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74',
    '682e7196-de43-4d3a-c4b7-1bb0ee779582', '6c756418-be5a-6aff-0e7c-83e9caf4cc28', '6ca46546-3e8c-e755-29b2-71e9a4796b1a', '6d796ecd-d6fb-2673-26d8-241fc8edb639',
    '6f9853bb-4d93-5315-8a35-d8e7bffaac00', '72ef1791-fc3d-5eb9-82f9-b11e4319664c', '730c2898-4ac5-0424-cecc-e171eae9cd23', '73a3b0ca-0a48-111c-1f52-7061ea30ba04',
    '76016512-b572-5a74-fda4-b04a1ed3c965', '77df6900-7a6c-ba66-81f5-dddc0199c6b2', '7a9d37ca-38a9-9806-aa44-779a00b9fcc7', '7c2433f7-f650-0d65-b404-ee5e869b699d',
    '7ccc2ec7-69b6-92f6-4686-7b91c8ab4649', '7d422983-7736-082b-b1f0-7a9f05428653', '7de80e02-0cb8-40ba-d43a-a56317200376', '7e4299be-1211-4721-bf77-d7b5135a6527',
    '7eb05ee9-f785-44f2-4060-d6830f84909d', '7f05c623-b2bc-d320-de47-efe81011d030', '7fc9cbd6-f241-c60d-d6f3-7c92afb006ef', '8392e70f-1210-288d-c904-2ed111db068a',
    '84f7f7fb-6032-deba-c455-0476cb8d6c30', '856df9c3-701c-763d-1645-6be8d8a504c0', '85a88812-9189-85d3-5e84-2b443758da11', '8740f2eb-dab5-0088-bce1-14a75a6b405f',
    '87423a62-27a9-405f-5218-e486818d3333', '88c5246a-1dab-e4f8-713a-e010c752dfb2', '89d4d03e-2047-c41d-abff-31278c5c124b', '8ae946b0-09f5-a280-af65-98a41b66e4cf',
    '8b492ef2-b16b-c46f-856a-7ece4628fce5', '8d382cab-766c-485d-7586-301061ed02b2', '8eeaff1e-e94b-5d7f-65e2-2cee58fe7d65', '8f7b4275-b407-2f4a-21f6-778871f6cb28',
    '8fe890b4-d7c8-47d0-dde4-49a1877c5a94', '90542c5b-805f-676e-0ded-dda2bcc3fd6c', '90d37a10-bb81-f7f1-acab-828bd0156ecb', '919fa354-6f32-271d-f874-de87522949e6',
    '91b38ded-e85f-948f-3d76-3726720f096e', '91f924b7-2755-b6f0-3d3b-993b661ce8be', '92cea08d-873e-be12-7629-8f8b3aad9057', '93877a10-914b-4001-9a04-f875b62f7a74',
    '944fdbc0-4c52-4790-e809-ab67f381e020', '94f1e6aa-ce59-0eea-3658-f10b8c33c79b', '9682cdf0-a5c3-c2d8-0593-3f7dbc76d264', '97b9d80a-bb7a-f47f-2c28-3a402c726dc4',
    '97d27a6b-386a-886c-c532-3848a47852c8', '99c17c23-cfd6-41bb-e32b-3587b35574d0', '99c46f51-10d4-c80d-569b-431163a08ba9', '9c46372d-b1d6-ebc4-eb1f-eabbd418907b',
    '9cf94f99-770f-c668-2945-7a207d029e56', '9ddbeb1f-f362-2cc2-b3a5-238e6de35eaa', '9f72539b-ffcf-f3b2-1ed2-7ed123a7059d', '9fceb0d5-c756-7c82-cdae-c569a1ce3e88',
    'a0ada8f4-a0de-5ebe-769f-94959d496017', 'a3bf67c7-fe60-369d-6de2-54bcba3a71a7', 'a53fe992-aa64-4486-852d-b2bc27361c12', 'a7267121-87a2-db50-b024-ff02deb91b02',
    'a7b2a100-9366-1002-c558-12906b908a1b', 'a9d4ad35-0dc9-c339-a227-3d3a5beec5cb', 'aa1caedd-3dd7-acc8-61cc-60eddbc14509', 'ab18fef1-79af-d704-f6a5-a2f1d82a3adb',
    'ad3fa804-0286-87a7-88c0-36f844a41b45', 'ad702758-5e3f-29ff-6fab-5593df4d48c7', 'ae831aac-86e1-742e-cc4e-3e88e80facbe', 'b15801c3-ba2f-bf0f-86af-61882f703f6a',
    'b3cbc388-4e0f-dd77-8564-914ead6e2f12', 'b3e3d48b-e6bf-c1a9-4d2a-061fbc737cfe', 'b7290ec9-1c5a-32bd-9560-9d8463eee431', 'b77a3087-27de-4131-0bd0-297c4a7b22b7',
    'b9a66b7e-c385-02fb-3e32-c5d82e4e9485', 'b9aecd1f-21a9-2df0-5cb8-a015a841c918', 'b9f6f2bb-104e-1e5c-2d5c-537173c13ab4', 'bbcedcc1-bc03-5cb7-71c6-2a9435e5a3e8',
    'c0fb998d-b48f-40ce-5860-2eadd2c3bb90', 'c2751812-feb7-f03b-68ce-a4e257eead48', 'c313267d-0283-8e2d-2c5c-4541cba3ccd9', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34',
    'c3fbbed9-6c30-1ce8-4180-57c976bf660d', 'c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', 'c685af42-8cb8-2393-2759-5651c6c3d852', 'c6b93d2f-07be-c92d-6aff-b7ee754836d9',
    'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'c9e2cb72-935a-32fa-b317-4b23ab198d39', 'ca405b5b-3c58-8917-709b-8fd92450b832', 'ccfaa9a6-2f40-d1af-fe18-8fa02f8aa572',
    'cf7edbe5-1210-e895-3b23-048204f23bd3', 'd0046b6c-9ee4-ce71-acbc-6f863000a675', 'd0207c76-9404-9f06-b50a-88d27139e011', 'd05f27fb-ba78-673a-2451-06cfff73e557',
    'd0830222-ebe3-2cd2-efac-05aa621c7353', 'd191c77f-f73f-386f-16c2-fe40d41f3083', 'd217f10c-1242-c7cd-e5b6-af8a5628297a', 'd2877aca-64f6-d47d-2045-5fed681919fb',
    'd2f025fb-3d20-e8ca-aea7-9aef6901479b', 'd74935c4-7741-e0f3-2c93-d5f47c6ceece', 'd7ab3758-595b-5e56-f206-0ff0f95a4001', 'da92c5b9-6d8d-ca35-934b-dd83c0bcd74e',
    'db05bf6e-af57-1710-628f-be735ad31335', 'dd227f65-9e4b-7082-89c7-42e62221f05b', 'dd84b5e8-e550-70ff-4944-db7c1eb7cc11', 'dd9cde60-9230-df8c-a424-1f5bfcff05a9',
    'dd9e2dde-9b56-4fcf-37f1-d6a56c58880b', 'e0bad159-ddf6-b4e7-59ca-efd9d2f76221', 'e121c8a6-26ad-7c34-f9af-c9b2e49b1859', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0',
    'e15e6803-0557-f9e9-691d-f462fd4eae18', 'e2672904-917d-a34a-0ef4-29bbdd95eca4', 'e4793072-8918-befb-d0ff-14523ba65b3c', 'e48d34f9-a0eb-3afc-02ee-14ba4c03197a',
    'e4abb72b-4b2c-8499-4bef-c09feddd9231', 'e528368d-6c4b-3609-454d-a1fb41b3f528', 'e5df29d0-ce0c-25f8-d6b5-37d9cffc7503', 'e938e900-970d-cf66-2ade-a0aaca3ff994',
    'e962115f-4609-0d5c-ec75-7c121884380d', 'e96452f5-6f54-72e9-28e1-de33907d1da6', 'eb2e2ab8-3197-2b3c-0aa7-054d8ecff0d1', 'ec36bae6-2e83-eb13-a687-feb19c6db160',
    'f12f01f4-08d6-6ead-ff7e-0e1d75762c38', 'f21612b2-ef6d-d7e3-6fae-f405ce556078', 'f36dacf1-6eb0-7e81-4d2f-ab912c7c7a36', 'f4211122-4191-3802-71a4-71a7756b2a37',
    'f61cbbb9-9aed-8a58-0cf0-5f481f274a15', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'f7647568-7e8a-d6de-7536-d18124ba7511', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2',
    'f83520d3-17cb-9102-efcc-77b6aab2e207', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'faec4cc3-c1d7-62aa-056a-58a6576a43b7', 'fb723e2e-88bf-1631-a2bb-a257a5340795',
    'fbb62345-42b4-d2fa-1d91-a13502b2dc39', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'fec50b25-50d1-8911-12b9-6e4141451724']::uuid[];
  v_target text := nullif(btrim(coalesce(current_setting('purple.seed_target', true), '')), '');
  v_pw     text := nullif(current_setting('purple.seed_password', true), '');
  v_url    text;
  v_ref    text;
  v_marker text;
  v_found  bigint;
begin
  -- ---------------------------------------------------------------- guard (allowlist, fails closed)
  if v_target is null then
    raise exception 'seed refused: purple.seed_target is not set (use ''local'' or an approved staging ref)';
  end if;
  if position(c_prod_ref in lower(v_target)) > 0 then
    raise exception 'seed refused: the target is the production project';
  end if;
  begin
    select decrypted_secret into strict v_url from vault.decrypted_secrets where name = 'project_url';
  exception
    when no_data_found then raise exception 'seed refused: Vault project_url is missing, so this database cannot be verified';
    when too_many_rows then raise exception 'seed refused: more than one Vault project_url';
    when others then raise exception 'seed refused: Vault project_url cannot be read (%)', sqlerrm;
  end;
  if v_url is null or btrim(v_url) = '' then
    raise exception 'seed refused: Vault project_url is empty';
  end if;
  if position(c_prod_ref in lower(v_url)) > 0 then
    raise exception 'seed refused: this database is the production project';
  end if;
  if v_target = 'local' then
    if v_url !~ '^https?://(127\.0\.0\.1|localhost|kong|host\.docker\.internal)(:[0-9]+)?/?$' then
      raise exception 'seed refused: target is local but project_url (%) is not a local address', v_url;
    end if;
  else
    v_ref := substring(v_url from '^https://([a-z0-9]{20})\.supabase\.co/?$');
    if v_ref is null or v_ref <> v_target then
      raise exception 'seed refused: target % does not match this database (%)', v_target, v_url;
    end if;
    if not (v_ref = any (c_staging_refs)) then
      raise exception 'seed refused: % is not an approved staging project', v_ref;
    end if;
  end if;
  if exists (select 1 from auth.users where email is null or email not like '%@seed.purple.test') then
    raise exception 'seed refused: this database has real (non-seed) accounts';
  end if;
  select decrypted_secret into v_marker from vault.decrypted_secrets where name = 'purple_seed_marker' limit 1;
  if v_marker is not null then
    raise exception 'seed refused: this database is already seeded (completion marker: %)', v_marker;
  end if;
  select (select count(*) from auth.users where email like '%@seed.purple.test' or id = any (c_seed_ids))
       + (select count(*) from auth.identities where id = any (c_seed_ids))
       + (select count(*) from public.profiles where id = any (c_seed_ids))
       + (select count(*) from public.listings where id = any (c_seed_ids))
       + (select count(*) from public.story_videos where id = any (c_seed_ids))
       + (select count(*) from public.story_comments where id = any (c_seed_ids))
       + (select count(*) from public.buyer_requests where id = any (c_seed_ids))
       + (select count(*) from public.request_offers where id = any (c_seed_ids))
       + (select count(*) from public.conversations where id = any (c_seed_ids))
       + (select count(*) from public.messages where id = any (c_seed_ids))
       + (select count(*) from public.checkouts where id = any (c_seed_ids))
       + (select count(*) from public.orders where id = any (c_seed_ids))
       + (select count(*) from public.bookings where id = any (c_seed_ids))
       + (select count(*) from public.reviews where id = any (c_seed_ids))
       + (select count(*) from public.reports where id = any (c_seed_ids))
       + (select count(*) from public.notifications where id = any (c_seed_ids))
       + (select count(*) from public.pro_entries where id = any (c_seed_ids))
       + (select count(*) from public.share_links where id = any (c_seed_ids))
    into v_found;
  if v_found > 0 then
    raise exception 'seed refused: % seed rows already exist without a completion marker (partial or older run); reset the database first', v_found;
  end if;

  -- ---------------------------------------------------------------- data
  -- 1. Accounts (auth.users + email identities). Profiles are created by the sign-up trigger.
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '97d27a6b-386a-886c-c532-3848a47852c8', 'authenticated', 'authenticated', 'admin@seed.purple.test',
    extensions.crypt(encode(extensions.gen_random_bytes(24), 'hex'), extensions.gen_salt('bf', 10)),  -- admin: never the shared test password
    now() - interval '86892 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_admin", "display_name": "Seed Admin"}'::jsonb, now() - interval '86892 minutes', now() - interval '86892 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('a7b2a100-9366-1002-c558-12906b908a1b', '97d27a6b-386a-886c-c532-3848a47852c8', '97d27a6b-386a-886c-c532-3848a47852c8', 'email',
    jsonb_build_object('sub', '97d27a6b-386a-886c-c532-3848a47852c8', 'email', 'admin@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '86892 minutes', now() - interval '86892 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '97d27a6b-386a-886c-c532-3848a47852c8'), state = 'Lagos', city = 'Ikeja' where id = '97d27a6b-386a-886c-c532-3848a47852c8';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '0f89d922-f179-c83a-4035-7269ab41815d', 'authenticated', 'authenticated', 'buyer.adaeze@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '84048 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_adaeze", "display_name": "Adaeze (seed buyer)"}'::jsonb, now() - interval '84048 minutes', now() - interval '84048 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('e121c8a6-26ad-7c34-f9af-c9b2e49b1859', '0f89d922-f179-c83a-4035-7269ab41815d', '0f89d922-f179-c83a-4035-7269ab41815d', 'email',
    jsonb_build_object('sub', '0f89d922-f179-c83a-4035-7269ab41815d', 'email', 'buyer.adaeze@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '84048 minutes', now() - interval '84048 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '0f89d922-f179-c83a-4035-7269ab41815d'), state = 'Lagos', city = 'Yaba' where id = '0f89d922-f179-c83a-4035-7269ab41815d';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'authenticated', 'authenticated', 'buyer.tunde@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '79421 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_tunde", "display_name": "Tunde (seed buyer)"}'::jsonb, now() - interval '79421 minutes', now() - interval '79421 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('120f4191-4f6e-6fb0-81e8-6ef84a7b5c4f', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'email',
    jsonb_build_object('sub', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'email', 'buyer.tunde@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '79421 minutes', now() - interval '79421 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'c6f897e2-0390-b115-2cf3-2871fcac34ba'), state = 'Lagos', city = 'Ikeja' where id = 'c6f897e2-0390-b115-2cf3-2871fcac34ba';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'authenticated', 'authenticated', 'buyer.chiamaka@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '72021 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_chiamaka", "display_name": "Chiamaka (seed buyer)"}'::jsonb, now() - interval '72021 minutes', now() - interval '72021 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('e2672904-917d-a34a-0ef4-29bbdd95eca4', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'email',
    jsonb_build_object('sub', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'email', 'buyer.chiamaka@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '72021 minutes', now() - interval '72021 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2'), state = 'Enugu', city = 'Enugu' where id = 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '0b247d05-4c2d-3855-10ca-1ac40c298aca', 'authenticated', 'authenticated', 'buyer.ibrahim@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '66500 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_ibrahim", "display_name": "Ibrahim (seed buyer)"}'::jsonb, now() - interval '66500 minutes', now() - interval '66500 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('dd9e2dde-9b56-4fcf-37f1-d6a56c58880b', '0b247d05-4c2d-3855-10ca-1ac40c298aca', '0b247d05-4c2d-3855-10ca-1ac40c298aca', 'email',
    jsonb_build_object('sub', '0b247d05-4c2d-3855-10ca-1ac40c298aca', 'email', 'buyer.ibrahim@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '66500 minutes', now() - interval '66500 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '0b247d05-4c2d-3855-10ca-1ac40c298aca'), state = 'Kano', city = 'Kano' where id = '0b247d05-4c2d-3855-10ca-1ac40c298aca';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '1552c7e1-cc9c-93b7-ba81-3020842f3191', 'authenticated', 'authenticated', 'buyer.funmi@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '58179 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_funmi", "display_name": "Funmi (seed buyer)"}'::jsonb, now() - interval '58179 minutes', now() - interval '58179 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('c685af42-8cb8-2393-2759-5651c6c3d852', '1552c7e1-cc9c-93b7-ba81-3020842f3191', '1552c7e1-cc9c-93b7-ba81-3020842f3191', 'email',
    jsonb_build_object('sub', '1552c7e1-cc9c-93b7-ba81-3020842f3191', 'email', 'buyer.funmi@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '58179 minutes', now() - interval '58179 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '1552c7e1-cc9c-93b7-ba81-3020842f3191'), state = 'Oyo', city = 'Ibadan' where id = '1552c7e1-cc9c-93b7-ba81-3020842f3191';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'authenticated', 'authenticated', 'buyer.emeka@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '47974 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_emeka", "display_name": "Emeka (seed buyer)"}'::jsonb, now() - interval '47974 minutes', now() - interval '47974 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('fbb62345-42b4-d2fa-1d91-a13502b2dc39', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'email',
    jsonb_build_object('sub', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'email', 'buyer.emeka@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '47974 minutes', now() - interval '47974 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '078cf7cd-d43e-8909-4e82-3a8f54700ba4'), state = 'Rivers', city = 'Port Harcourt' where id = '078cf7cd-d43e-8909-4e82-3a8f54700ba4';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'authenticated', 'authenticated', 'buyer.zainab@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '39250 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_zainab", "display_name": "Zainab (seed buyer)"}'::jsonb, now() - interval '39250 minutes', now() - interval '39250 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('dd227f65-9e4b-7082-89c7-42e62221f05b', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'email',
    jsonb_build_object('sub', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'email', 'buyer.zainab@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '39250 minutes', now() - interval '39250 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'f6d2c74a-a808-09cc-0aca-251d36d2d751'), state = 'FCT', city = 'Abuja' where id = 'f6d2c74a-a808-09cc-0aca-251d36d2d751';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '2b7d6168-fb32-2091-6848-977c9ebe9666', 'authenticated', 'authenticated', 'buyer.segun@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '30296 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_segun", "display_name": "Segun (seed buyer)"}'::jsonb, now() - interval '30296 minutes', now() - interval '30296 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('8d382cab-766c-485d-7586-301061ed02b2', '2b7d6168-fb32-2091-6848-977c9ebe9666', '2b7d6168-fb32-2091-6848-977c9ebe9666', 'email',
    jsonb_build_object('sub', '2b7d6168-fb32-2091-6848-977c9ebe9666', 'email', 'buyer.segun@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '30296 minutes', now() - interval '30296 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '2b7d6168-fb32-2091-6848-977c9ebe9666'), state = 'Lagos', city = 'Surulere' where id = '2b7d6168-fb32-2091-6848-977c9ebe9666';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'authenticated', 'authenticated', 'buyer.ngozi@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '20441 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_ngozi", "display_name": "Ngozi (seed buyer)"}'::jsonb, now() - interval '20441 minutes', now() - interval '20441 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('5d9ca47d-593a-2ab2-1862-740d33c9f812', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'email',
    jsonb_build_object('sub', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'email', 'buyer.ngozi@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '20441 minutes', now() - interval '20441 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '2e79d2f5-2d03-9d9f-7ee6-18434adc0747'), state = 'Enugu', city = 'Nsukka' where id = '2e79d2f5-2d03-9d9f-7ee6-18434adc0747';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'd0046b6c-9ee4-ce71-acbc-6f863000a675', 'authenticated', 'authenticated', 'buyer.musa@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '14451 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_musa", "display_name": "Musa (seed buyer, banned)"}'::jsonb, now() - interval '14451 minutes', now() - interval '14451 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('3017a650-3ea5-db08-cd17-5be73045c65b', 'd0046b6c-9ee4-ce71-acbc-6f863000a675', 'd0046b6c-9ee4-ce71-acbc-6f863000a675', 'email',
    jsonb_build_object('sub', 'd0046b6c-9ee4-ce71-acbc-6f863000a675', 'email', 'buyer.musa@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '14451 minutes', now() - interval '14451 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'd0046b6c-9ee4-ce71-acbc-6f863000a675'), state = 'Kaduna', city = 'Kaduna' where id = 'd0046b6c-9ee4-ce71-acbc-6f863000a675';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '3850c6d8-9934-1f10-5264-6740dff2d7d6', 'authenticated', 'authenticated', 'buyer.bisi@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '8826 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_bisi", "display_name": "Bisi (seed buyer, suspended)"}'::jsonb, now() - interval '8826 minutes', now() - interval '8826 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('e15e6803-0557-f9e9-691d-f462fd4eae18', '3850c6d8-9934-1f10-5264-6740dff2d7d6', '3850c6d8-9934-1f10-5264-6740dff2d7d6', 'email',
    jsonb_build_object('sub', '3850c6d8-9934-1f10-5264-6740dff2d7d6', 'email', 'buyer.bisi@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '8826 minutes', now() - interval '8826 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '3850c6d8-9934-1f10-5264-6740dff2d7d6'), state = 'Ogun', city = 'Abeokuta' where id = '3850c6d8-9934-1f10-5264-6740dff2d7d6';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '0c2aad9d-7eae-3d0e-a0ea-ca9cd49d9cd1', 'authenticated', 'authenticated', 'buyer.kelechi@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '4609 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_kelechi", "display_name": "Kelechi (seed buyer, leaving)"}'::jsonb, now() - interval '4609 minutes', now() - interval '4609 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('31c9221a-f6c1-4d62-2310-31a3cc25e981', '0c2aad9d-7eae-3d0e-a0ea-ca9cd49d9cd1', '0c2aad9d-7eae-3d0e-a0ea-ca9cd49d9cd1', 'email',
    jsonb_build_object('sub', '0c2aad9d-7eae-3d0e-a0ea-ca9cd49d9cd1', 'email', 'buyer.kelechi@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '4609 minutes', now() - interval '4609 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '0c2aad9d-7eae-3d0e-a0ea-ca9cd49d9cd1'), state = 'Lagos', city = 'Lekki' where id = '0c2aad9d-7eae-3d0e-a0ea-ca9cd49d9cd1';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'authenticated', 'authenticated', 'seller.adire_house@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '82108 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_adire_house", "display_name": "Adire House (seed)"}'::jsonb, now() - interval '82108 minutes', now() - interval '82108 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('b3cbc388-4e0f-dd77-8564-914ead6e2f12', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'email',
    jsonb_build_object('sub', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'email', 'seller.adire_house@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '82108 minutes', now() - interval '82108 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '43be0c1d-e9b1-6e0b-784d-30ccc14e8729'), state = 'Lagos', city = 'Yaba' where id = '43be0c1d-e9b1-6e0b-784d-30ccc14e8729';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '065cae22-135c-dc6a-d539-8cfc70565d94', 'authenticated', 'authenticated', 'seller.kampala_corner@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '75378 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_kampala_corner", "display_name": "Kampala Corner (seed)"}'::jsonb, now() - interval '75378 minutes', now() - interval '75378 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('e4abb72b-4b2c-8499-4bef-c09feddd9231', '065cae22-135c-dc6a-d539-8cfc70565d94', '065cae22-135c-dc6a-d539-8cfc70565d94', 'email',
    jsonb_build_object('sub', '065cae22-135c-dc6a-d539-8cfc70565d94', 'email', 'seller.kampala_corner@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '75378 minutes', now() - interval '75378 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '065cae22-135c-dc6a-d539-8cfc70565d94'), state = 'Oyo', city = 'Ibadan' where id = '065cae22-135c-dc6a-d539-8cfc70565d94';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '5b685f38-9471-8789-5ba8-9609f1ee3484', 'authenticated', 'authenticated', 'seller.ankara_atelier@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '17799 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_ankara_atelier", "display_name": "Ankara Atelier (seed)"}'::jsonb, now() - interval '17799 minutes', now() - interval '17799 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('7de80e02-0cb8-40ba-d43a-a56317200376', '5b685f38-9471-8789-5ba8-9609f1ee3484', '5b685f38-9471-8789-5ba8-9609f1ee3484', 'email',
    jsonb_build_object('sub', '5b685f38-9471-8789-5ba8-9609f1ee3484', 'email', 'seller.ankara_atelier@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '17799 minutes', now() - interval '17799 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '5b685f38-9471-8789-5ba8-9609f1ee3484'), state = 'Lagos', city = 'Lekki' where id = '5b685f38-9471-8789-5ba8-9609f1ee3484';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'authenticated', 'authenticated', 'seller.clay_and_kiln@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '69458 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_clay_and_kiln", "display_name": "Clay and Kiln (seed)"}'::jsonb, now() - interval '69458 minutes', now() - interval '69458 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('eb2e2ab8-3197-2b3c-0aa7-054d8ecff0d1', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'email',
    jsonb_build_object('sub', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'email', 'seller.clay_and_kiln@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '69458 minutes', now() - interval '69458 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '1734e54e-6df3-bd1b-3a18-07309e3d2c2f'), state = 'Enugu', city = 'Enugu' where id = '1734e54e-6df3-bd1b-3a18-07309e3d2c2f';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'authenticated', 'authenticated', 'seller.bead_works@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '63666 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_bead_works", "display_name": "Bead Works (seed)"}'::jsonb, now() - interval '63666 minutes', now() - interval '63666 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('6c756418-be5a-6aff-0e7c-83e9caf4cc28', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'email',
    jsonb_build_object('sub', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'email', 'seller.bead_works@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '63666 minutes', now() - interval '63666 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8'), state = 'FCT', city = 'Abuja' where id = '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'd2f025fb-3d20-e8ca-aea7-9aef6901479b', 'authenticated', 'authenticated', 'seller.canvas_corner@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '56734 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_canvas_corner", "display_name": "Canvas Corner (seed, suspended)"}'::jsonb, now() - interval '56734 minutes', now() - interval '56734 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('d191c77f-f73f-386f-16c2-fe40d41f3083', 'd2f025fb-3d20-e8ca-aea7-9aef6901479b', 'd2f025fb-3d20-e8ca-aea7-9aef6901479b', 'email',
    jsonb_build_object('sub', 'd2f025fb-3d20-e8ca-aea7-9aef6901479b', 'email', 'seller.canvas_corner@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '56734 minutes', now() - interval '56734 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'd2f025fb-3d20-e8ca-aea7-9aef6901479b'), state = 'Ogun', city = 'Abeokuta' where id = 'd2f025fb-3d20-e8ca-aea7-9aef6901479b';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'authenticated', 'authenticated', 'seller.devcraft@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '68244 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_devcraft", "display_name": "DevCraft Studio (seed)"}'::jsonb, now() - interval '68244 minutes', now() - interval '68244 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('4488d9f0-6c5d-c839-48e8-092ea18739d4', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'email',
    jsonb_build_object('sub', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'email', 'seller.devcraft@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '68244 minutes', now() - interval '68244 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0'), state = 'Lagos', city = 'Ikeja' where id = 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'authenticated', 'authenticated', 'seller.tobi_dev@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '52061 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_tobi_dev", "display_name": "Tobi (seed freelancer)"}'::jsonb, now() - interval '52061 minutes', now() - interval '52061 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('5f1842b5-ea5e-2002-e0c4-98763a25242d', '8f7b4275-b407-2f4a-21f6-778871f6cb28', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'email',
    jsonb_build_object('sub', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'email', 'seller.tobi_dev@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '52061 minutes', now() - interval '52061 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '8f7b4275-b407-2f4a-21f6-778871f6cb28'), state = 'Oyo', city = 'Ibadan' where id = '8f7b4275-b407-2f4a-21f6-778871f6cb28';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '84f7f7fb-6032-deba-c455-0476cb8d6c30', 'authenticated', 'authenticated', 'seller.data_amaka@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '43259 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_data_amaka", "display_name": "Amaka Data (seed)"}'::jsonb, now() - interval '43259 minutes', now() - interval '43259 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('2e459972-82bb-edae-74c7-a0bede719812', '84f7f7fb-6032-deba-c455-0476cb8d6c30', '84f7f7fb-6032-deba-c455-0476cb8d6c30', 'email',
    jsonb_build_object('sub', '84f7f7fb-6032-deba-c455-0476cb8d6c30', 'email', 'seller.data_amaka@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '43259 minutes', now() - interval '43259 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '84f7f7fb-6032-deba-c455-0476cb8d6c30'), state = 'Enugu', city = 'Enugu' where id = '84f7f7fb-6032-deba-c455-0476cb8d6c30';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'authenticated', 'authenticated', 'seller.pixel_forge@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '60486 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_pixel_forge", "display_name": "Pixel Forge (seed)"}'::jsonb, now() - interval '60486 minutes', now() - interval '60486 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('f36dacf1-6eb0-7e81-4d2f-ab912c7c7a36', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'email',
    jsonb_build_object('sub', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'email', 'seller.pixel_forge@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '60486 minutes', now() - interval '60486 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34'), state = 'Lagos', city = 'Yaba' where id = 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '388fc4c1-d047-6efc-6d86-abdc0435b188', 'authenticated', 'authenticated', 'seller.logo_lab@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '26157 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_logo_lab", "display_name": "Logo Lab (seed)"}'::jsonb, now() - interval '26157 minutes', now() - interval '26157 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('e0bad159-ddf6-b4e7-59ca-efd9d2f76221', '388fc4c1-d047-6efc-6d86-abdc0435b188', '388fc4c1-d047-6efc-6d86-abdc0435b188', 'email',
    jsonb_build_object('sub', '388fc4c1-d047-6efc-6d86-abdc0435b188', 'email', 'seller.logo_lab@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '26157 minutes', now() - interval '26157 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '388fc4c1-d047-6efc-6d86-abdc0435b188'), state = 'Kano', city = 'Kano' where id = '388fc4c1-d047-6efc-6d86-abdc0435b188';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '730c2898-4ac5-0424-cecc-e171eae9cd23', 'authenticated', 'authenticated', 'seller.spark_electric@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '65031 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_spark_electric", "display_name": "Spark Electric (seed)"}'::jsonb, now() - interval '65031 minutes', now() - interval '65031 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('919fa354-6f32-271d-f874-de87522949e6', '730c2898-4ac5-0424-cecc-e171eae9cd23', '730c2898-4ac5-0424-cecc-e171eae9cd23', 'email',
    jsonb_build_object('sub', '730c2898-4ac5-0424-cecc-e171eae9cd23', 'email', 'seller.spark_electric@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '65031 minutes', now() - interval '65031 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '730c2898-4ac5-0424-cecc-e171eae9cd23'), state = 'Lagos', city = 'Surulere' where id = '730c2898-4ac5-0424-cecc-e171eae9cd23';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'authenticated', 'authenticated', 'seller.cool_air_fix@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '59529 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_cool_air_fix", "display_name": "Cool Air Fix (seed)"}'::jsonb, now() - interval '59529 minutes', now() - interval '59529 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('d05f27fb-ba78-673a-2451-06cfff73e557', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'email',
    jsonb_build_object('sub', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'email', 'seller.cool_air_fix@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '59529 minutes', now() - interval '59529 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '66f3d05d-39c9-abbc-dab0-8e81f36d5c74'), state = 'FCT', city = 'Abuja' where id = '66f3d05d-39c9-abbc-dab0-8e81f36d5c74';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'b7290ec9-1c5a-32bd-9560-9d8463eee431', 'authenticated', 'authenticated', 'seller.clean_sweep@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '50462 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_clean_sweep", "display_name": "Clean Sweep (seed)"}'::jsonb, now() - interval '50462 minutes', now() - interval '50462 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('944fdbc0-4c52-4790-e809-ab67f381e020', 'b7290ec9-1c5a-32bd-9560-9d8463eee431', 'b7290ec9-1c5a-32bd-9560-9d8463eee431', 'email',
    jsonb_build_object('sub', 'b7290ec9-1c5a-32bd-9560-9d8463eee431', 'email', 'seller.clean_sweep@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '50462 minutes', now() - interval '50462 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'b7290ec9-1c5a-32bd-9560-9d8463eee431'), state = 'Rivers', city = 'Port Harcourt' where id = 'b7290ec9-1c5a-32bd-9560-9d8463eee431';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '3022de0b-4a28-5e57-1148-55296124fb25', 'authenticated', 'authenticated', 'seller.fix_it_femi@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '11690 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_fix_it_femi", "display_name": "Fix It Femi (seed)"}'::jsonb, now() - interval '11690 minutes', now() - interval '11690 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('e938e900-970d-cf66-2ade-a0aaca3ff994', '3022de0b-4a28-5e57-1148-55296124fb25', '3022de0b-4a28-5e57-1148-55296124fb25', 'email',
    jsonb_build_object('sub', '3022de0b-4a28-5e57-1148-55296124fb25', 'email', 'seller.fix_it_femi@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '11690 minutes', now() - interval '11690 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '3022de0b-4a28-5e57-1148-55296124fb25'), state = 'Kaduna', city = 'Kaduna' where id = '3022de0b-4a28-5e57-1148-55296124fb25';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'authenticated', 'authenticated', 'seller.lens_and_light@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '70883 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_lens_and_light", "display_name": "Lens and Light (seed)"}'::jsonb, now() - interval '70883 minutes', now() - interval '70883 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('f7647568-7e8a-d6de-7536-d18124ba7511', '88c5246a-1dab-e4f8-713a-e010c752dfb2', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'email',
    jsonb_build_object('sub', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'email', 'seller.lens_and_light@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '70883 minutes', now() - interval '70883 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '88c5246a-1dab-e4f8-713a-e010c752dfb2'), state = 'Lagos', city = 'Lekki' where id = '88c5246a-1dab-e4f8-713a-e010c752dfb2';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'authenticated', 'authenticated', 'seller.voice_by_ife@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '45036 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_voice_by_ife", "display_name": "Voice by Ife (seed)"}'::jsonb, now() - interval '45036 minutes', now() - interval '45036 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('7f05c623-b2bc-d320-de47-efe81011d030', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'email',
    jsonb_build_object('sub', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'email', 'seller.voice_by_ife@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '45036 minutes', now() - interval '45036 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2'), state = 'Oyo', city = 'Ibadan' where id = 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', '19d2c070-1501-1c48-da57-d74352bbde02', 'authenticated', 'authenticated', 'seller.drum_circle@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '37443 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_drum_circle", "display_name": "Drum Circle Band (seed)"}'::jsonb, now() - interval '37443 minutes', now() - interval '37443 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('aa1caedd-3dd7-acc8-61cc-60eddbc14509', '19d2c070-1501-1c48-da57-d74352bbde02', '19d2c070-1501-1c48-da57-d74352bbde02', 'email',
    jsonb_build_object('sub', '19d2c070-1501-1c48-da57-d74352bbde02', 'email', 'seller.drum_circle@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '37443 minutes', now() - interval '37443 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = '19d2c070-1501-1c48-da57-d74352bbde02'), state = 'Lagos', city = 'Ikeja' where id = '19d2c070-1501-1c48-da57-d74352bbde02';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)
  values ('00000000-0000-0000-0000-000000000000', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'authenticated', 'authenticated', 'seller.mc_kunle@seed.purple.test',
    extensions.crypt(coalesce(v_pw, encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf', 10)),
    now() - interval '23097 minutes', '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": "seed_mc_kunle", "display_name": "MC Kunle (seed)"}'::jsonb, now() - interval '23097 minutes', now() - interval '23097 minutes',
    '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)
  values ('015b4863-6fab-ffa8-9f8e-fb119a7d1e93', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'email',
    jsonb_build_object('sub', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'email', 'seller.mc_kunle@seed.purple.test', 'email_verified', true, 'phone_verified', false), now() - interval '23097 minutes', now() - interval '23097 minutes');
  update public.profiles set created_at = (select created_at from auth.users where id = 'fabae036-2d8c-f09e-cbd7-101d945f64a0'), state = 'Lagos', city = 'Surulere' where id = 'fabae036-2d8c-f09e-cbd7-101d945f64a0';

  -- 2. Roles and shop details
  update public.profiles set role = 'admin' where id = '97d27a6b-386a-886c-c532-3848a47852c8';
  update public.profiles set role = 'seller', business_name = 'Adire House (seed)', headline = 'Hand-dyed adire from Abeokuta indigo', bio = 'Small studio making indigo adire fabric and ready-to-wear pieces. Every piece is dyed by hand.',
    years_experience = 9, is_available = false, skills = '{}'::text[], languages = array['English', 'Yoruba']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = '43be0c1d-e9b1-6e0b-784d-30ccc14e8729';
  perform private.ensure_seller_register('43be0c1d-e9b1-6e0b-784d-30ccc14e8729');
  update public.profiles set role = 'seller', business_name = 'Kampala Corner (seed)', headline = 'Tie-dye kampala in bright colours', bio = 'Family workshop selling kampala fabric by the yard and simple dresses.',
    years_experience = 15, is_available = false, skills = '{}'::text[], languages = array['English', 'Yoruba']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = '065cae22-135c-dc6a-d539-8cfc70565d94';
  perform private.ensure_seller_register('065cae22-135c-dc6a-d539-8cfc70565d94');
  update public.profiles set role = 'seller', business_name = 'Ankara Atelier (seed)', headline = 'Ankara two-pieces made to order', bio = 'New tailoring studio. ID check in progress.',
    years_experience = 2, is_available = false, skills = '{}'::text[], languages = array['English']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = '5b685f38-9471-8789-5ba8-9609f1ee3484';
  perform private.ensure_seller_register('5b685f38-9471-8789-5ba8-9609f1ee3484');
  update public.profiles set role = 'seller', business_name = 'Clay and Kiln (seed)', headline = 'Wheel-thrown pottery and vases', bio = 'Potter working with local clay. Vases, bowls and planters fired in a wood kiln.',
    years_experience = 11, is_available = false, skills = '{}'::text[], languages = array['English', 'Igbo']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = '1734e54e-6df3-bd1b-3a18-07309e3d2c2f';
  perform private.ensure_seller_register('1734e54e-6df3-bd1b-3a18-07309e3d2c2f');
  update public.profiles set role = 'seller', business_name = 'Bead Works (seed)', headline = 'Coral and glass bead jewellery', bio = 'Bead necklaces, bracelets and bridal sets, strung by hand.',
    years_experience = 7, is_available = false, skills = '{}'::text[], languages = array['English', 'Hausa']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8';
  perform private.ensure_seller_register('11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8');
  update public.profiles set role = 'seller', business_name = 'Canvas Corner (seed, suspended)', headline = 'Acrylic paintings of city life', bio = 'Painter selling originals and prints. Account suspended for a test case.',
    years_experience = 5, is_available = false, skills = '{}'::text[], languages = array['English']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = 'd2f025fb-3d20-e8ca-aea7-9aef6901479b';
  perform private.ensure_seller_register('d2f025fb-3d20-e8ca-aea7-9aef6901479b');
  update public.profiles set role = 'seller', business_name = 'DevCraft Studio (seed)', headline = 'Web apps for small businesses', bio = 'Two developers building websites, online stores and booking systems for small firms.',
    years_experience = 8, is_available = true, skills = array['Next.js', 'TypeScript', 'PostgreSQL', 'UI design']::text[], languages = array['English']::text[],
    pro_mode = 'professional'::public.pro_mode, pro_public = true where id = 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0';
  perform private.ensure_seller_register('e130dba3-7e8d-5d3b-7b0b-f382d5b383d0');
  update public.profiles set role = 'seller', business_name = 'Tobi (seed freelancer)', headline = 'Mobile developer, Flutter and Kotlin', bio = 'Freelance mobile developer. I build and maintain Android and iOS apps.',
    years_experience = 5, is_available = true, skills = array['Flutter', 'Kotlin', 'Firebase']::text[], languages = array['English', 'Yoruba']::text[],
    pro_mode = 'professional'::public.pro_mode, pro_public = true where id = '8f7b4275-b407-2f4a-21f6-778871f6cb28';
  perform private.ensure_seller_register('8f7b4275-b407-2f4a-21f6-778871f6cb28');
  update public.profiles set role = 'seller', business_name = 'Amaka Data (seed)', headline = 'Spreadsheets, dashboards and data cleaning', bio = 'Data analyst helping shops make sense of sales records.',
    years_experience = 4, is_available = true, skills = array['Excel', 'SQL', 'Power BI']::text[], languages = array['English', 'Igbo']::text[],
    pro_mode = 'professional'::public.pro_mode, pro_public = false where id = '84f7f7fb-6032-deba-c455-0476cb8d6c30';
  perform private.ensure_seller_register('84f7f7fb-6032-deba-c455-0476cb8d6c30');
  update public.profiles set role = 'seller', business_name = 'Pixel Forge (seed)', headline = 'Brand identity and packaging design', bio = 'Design studio for logos, packaging and social media templates.',
    years_experience = 6, is_available = true, skills = array['Branding', 'Illustration', 'Packaging']::text[], languages = array['English']::text[],
    pro_mode = 'creative_space'::public.pro_mode, pro_public = true where id = 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34';
  perform private.ensure_seller_register('c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34');
  update public.profiles set role = 'seller', business_name = 'Logo Lab (seed)', headline = 'Fast logo design', bio = 'Logo designer. Page not public yet.',
    years_experience = 3, is_available = true, skills = array['Logo design']::text[], languages = array['English', 'Hausa']::text[],
    pro_mode = 'professional'::public.pro_mode, pro_public = false where id = '388fc4c1-d047-6efc-6d86-abdc0435b188';
  perform private.ensure_seller_register('388fc4c1-d047-6efc-6d86-abdc0435b188');
  update public.profiles set role = 'seller', business_name = 'Spark Electric (seed)', headline = 'Licensed electrician, wiring and repairs', bio = 'House wiring, fault finding, inverter installs and socket repairs.',
    years_experience = 12, is_available = true, skills = '{}'::text[], languages = array['English', 'Yoruba']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = '730c2898-4ac5-0424-cecc-e171eae9cd23';
  perform private.ensure_seller_register('730c2898-4ac5-0424-cecc-e171eae9cd23');
  update public.profiles set role = 'seller', business_name = 'Cool Air Fix (seed)', headline = 'AC installation and servicing', bio = 'Air conditioner servicing, gas refills and installation.',
    years_experience = 10, is_available = true, skills = '{}'::text[], languages = array['English', 'Hausa']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = '66f3d05d-39c9-abbc-dab0-8e81f36d5c74';
  perform private.ensure_seller_register('66f3d05d-39c9-abbc-dab0-8e81f36d5c74');
  update public.profiles set role = 'seller', business_name = 'Clean Sweep (seed)', headline = 'Home and office deep cleaning', bio = 'Cleaning crew for homes, offices and post-renovation jobs.',
    years_experience = 6, is_available = true, skills = '{}'::text[], languages = array['English']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = 'b7290ec9-1c5a-32bd-9560-9d8463eee431';
  perform private.ensure_seller_register('b7290ec9-1c5a-32bd-9560-9d8463eee431');
  update public.profiles set role = 'seller', business_name = 'Fix It Femi (seed)', headline = 'Plumbing and small repairs', bio = 'Plumber. Waiting for ID check, so listings are drafts.',
    years_experience = 4, is_available = true, skills = '{}'::text[], languages = array['English', 'Hausa']::text[],
    pro_mode = null::public.pro_mode, pro_public = false where id = '3022de0b-4a28-5e57-1148-55296124fb25';
  perform private.ensure_seller_register('3022de0b-4a28-5e57-1148-55296124fb25');
  update public.profiles set role = 'seller', business_name = 'Lens and Light (seed)', headline = 'Event and portrait photography', bio = 'Photographer covering weddings, naming ceremonies and studio portraits.',
    years_experience = 9, is_available = true, skills = array['Photography', 'Lightroom', 'Portraits']::text[], languages = array['English', 'Yoruba']::text[],
    pro_mode = 'creative_space'::public.pro_mode, pro_public = true where id = '88c5246a-1dab-e4f8-713a-e010c752dfb2';
  perform private.ensure_seller_register('88c5246a-1dab-e4f8-713a-e010c752dfb2');
  update public.profiles set role = 'seller', business_name = 'Voice by Ife (seed)', headline = 'Voice-over for adverts and audiobooks', bio = 'Voice artist with a home studio. English, Yoruba and Pidgin reads.',
    years_experience = 6, is_available = true, skills = array['Voice-over', 'Audio editing']::text[], languages = array['English', 'Yoruba', 'Pidgin']::text[],
    pro_mode = 'creative_space'::public.pro_mode, pro_public = true where id = 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2';
  perform private.ensure_seller_register('f7ceeee9-03bd-e75d-b2a4-419d72ba62b2');
  update public.profiles set role = 'seller', business_name = 'Drum Circle Band (seed)', headline = 'Live highlife and talking drum band', bio = 'Six-piece band for weddings and parties.',
    years_experience = 11, is_available = true, skills = array['Highlife', 'Talking drum']::text[], languages = array['English', 'Yoruba']::text[],
    pro_mode = 'creative_space'::public.pro_mode, pro_public = true where id = '19d2c070-1501-1c48-da57-d74352bbde02';
  perform private.ensure_seller_register('19d2c070-1501-1c48-da57-d74352bbde02');
  update public.profiles set role = 'seller', business_name = 'MC Kunle (seed)', headline = 'Event host and MC', bio = 'Bilingual MC for parties and corporate events.',
    years_experience = 7, is_available = true, skills = array['Event hosting']::text[], languages = array['English', 'Yoruba']::text[],
    pro_mode = 'professional'::public.pro_mode, pro_public = false where id = 'fabae036-2d8c-f09e-cbd7-101d945f64a0';
  perform private.ensure_seller_register('fabae036-2d8c-f09e-cbd7-101d945f64a0');

  -- 3. ID verification (approved ones turn on the verified badge; required before home-service listings)
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Adire House (seed)', '1001', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('065cae22-135c-dc6a-d539-8cfc70565d94', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Kampala Corner (seed)', '1002', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('5b685f38-9471-8789-5ba8-9609f1ee3484', 'pending'::public.verification_status, 'nin', '5b685f38-9471-8789-5ba8-9609f1ee3484/seed/id-document.jpg', null, 'Seed Test Bank', '000',
    'Ankara Atelier (seed)', '1003', null, now() - interval '3 days', null, null);
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Clay and Kiln (seed)', '1004', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Bead Works (seed)', '1005', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('d2f025fb-3d20-e8ca-aea7-9aef6901479b', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Canvas Corner (seed, suspended)', '1006', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'DevCraft Studio (seed)', '1007', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('8f7b4275-b407-2f4a-21f6-778871f6cb28', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Tobi (seed freelancer)', '1008', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('84f7f7fb-6032-deba-c455-0476cb8d6c30', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Amaka Data (seed)', '1009', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Pixel Forge (seed)', '1010', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Spark Electric (seed)', '1011', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Cool Air Fix (seed)', '1012', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Clean Sweep (seed)', '1013', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('3022de0b-4a28-5e57-1148-55296124fb25', 'pending'::public.verification_status, 'nin', '3022de0b-4a28-5e57-1148-55296124fb25/seed/id-document.jpg', null, 'Seed Test Bank', '000',
    'Fix It Femi (seed)', '1014', null, now() - interval '3 days', null, null);
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('88c5246a-1dab-e4f8-713a-e010c752dfb2', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Lens and Light (seed)', '1015', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Voice by Ife (seed)', '1016', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('19d2c070-1501-1c48-da57-d74352bbde02', 'approved'::public.verification_status, 'nin', null, now() - interval '1 day', 'Seed Test Bank', '000',
    'Drum Circle Band (seed)', '1017', null, now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');
  insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,
    account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)
  values ('fabae036-2d8c-f09e-cbd7-101d945f64a0', 'rejected'::public.verification_status, 'nin', 'fabae036-2d8c-f09e-cbd7-101d945f64a0/seed/id-document.jpg', null, 'Seed Test Bank', '000',
    'MC Kunle (seed)', '1018', 'Seed: document photo is blurred.', now() - interval '3 days', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '2 days');

  -- 4. Listings and image paths (files are not uploaded; see docs)
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('5dd229ee-4840-ce1f-fb95-c9e949052242', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'product'::public.listing_type, 1, 'Indigo adire wrapper, two yards', 'Hand-dyed indigo adire, two yards, cotton. Soft after the first wash.', 1800000, false, false,
    12, 'delivery'::public.delivery_mode, 'Lagos', 'Yaba', 'approved'::public.listing_status, null, now() - interval '80640 minutes', now() - interval '80640 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('5dd229ee-4840-ce1f-fb95-c9e949052242', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/adire_wrapper-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('5dd229ee-4840-ce1f-fb95-c9e949052242', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/adire_wrapper-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('c9e2cb72-935a-32fa-b317-4b23ab198d39', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'product'::public.listing_type, 1, 'Adire short-sleeve shirt', 'Unisex adire shirt in sizes S to XXL. Made to order in five working days.', 2500000, false, false,
    8, 'delivery'::public.delivery_mode, 'Lagos', 'Yaba', 'approved'::public.listing_status, null, now() - interval '80603 minutes', now() - interval '80603 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('c9e2cb72-935a-32fa-b317-4b23ab198d39', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/adire_shirt-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('c9e2cb72-935a-32fa-b317-4b23ab198d39', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/adire_shirt-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('5a8ae12d-45e5-5b02-4ed0-5f6a41264170', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'product'::public.listing_type, 1, 'Adire tote bag', 'Lined tote bag with inner pocket.', 950000, false, false,
    0, 'delivery'::public.delivery_mode, 'Lagos', 'Yaba', 'rejected'::public.listing_status, 'Seed: photos do not show the product clearly.', now() - interval '80566 minutes', now() - interval '80566 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('5a8ae12d-45e5-5b02-4ed0-5f6a41264170', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/adire_bag-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('5a8ae12d-45e5-5b02-4ed0-5f6a41264170', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/adire_bag-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('5bc541dd-6d66-1b2e-f2be-1fb6e7ba6c2c', '065cae22-135c-dc6a-d539-8cfc70565d94', 'product'::public.listing_type, 1, 'Kampala fabric by the yard', 'Bright tie-dye kampala, sold per yard. Choose colours at checkout.', 450000, true, false,
    40, 'pickup'::public.delivery_mode, 'Oyo', 'Ibadan', 'approved'::public.listing_status, null, now() - interval '73329 minutes', now() - interval '73329 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('5bc541dd-6d66-1b2e-f2be-1fb6e7ba6c2c', '065cae22-135c-dc6a-d539-8cfc70565d94/seed/kampala_yard-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('5bc541dd-6d66-1b2e-f2be-1fb6e7ba6c2c', '065cae22-135c-dc6a-d539-8cfc70565d94/seed/kampala_yard-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('65003b04-4337-0ee0-54a7-8af5dc80cbdf', '065cae22-135c-dc6a-d539-8cfc70565d94', 'product'::public.listing_type, 1, 'Kampala midi dress', 'Simple midi dress with pockets.', 2200000, false, false,
    5, 'delivery'::public.delivery_mode, 'Oyo', 'Ibadan', 'approved'::public.listing_status, null, now() - interval '73292 minutes', now() - interval '73292 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('65003b04-4337-0ee0-54a7-8af5dc80cbdf', '065cae22-135c-dc6a-d539-8cfc70565d94/seed/kampala_dress-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('65003b04-4337-0ee0-54a7-8af5dc80cbdf', '065cae22-135c-dc6a-d539-8cfc70565d94/seed/kampala_dress-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('13ab1241-58ee-bf89-ae2f-88f234cd0c57', '5b685f38-9471-8789-5ba8-9609f1ee3484', 'product'::public.listing_type, 1, 'Ankara two-piece set', 'Top and trousers, made to measure.', 3500000, true, false,
    3, 'delivery'::public.delivery_mode, 'Lagos', 'Lekki', 'pending'::public.listing_status, null, now() - interval '15655 minutes', now() - interval '15655 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('13ab1241-58ee-bf89-ae2f-88f234cd0c57', '5b685f38-9471-8789-5ba8-9609f1ee3484/seed/ankara_two_piece-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('13ab1241-58ee-bf89-ae2f-88f234cd0c57', '5b685f38-9471-8789-5ba8-9609f1ee3484/seed/ankara_two_piece-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('7ccc2ec7-69b6-92f6-4686-7b91c8ab4649', '5b685f38-9471-8789-5ba8-9609f1ee3484', 'product'::public.listing_type, 1, 'Ankara bucket hat', 'Reversible bucket hat.', 600000, false, false,
    10, 'delivery'::public.delivery_mode, 'Lagos', 'Lekki', 'draft'::public.listing_status, null, now() - interval '15618 minutes', now() - interval '15618 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('7ccc2ec7-69b6-92f6-4686-7b91c8ab4649', '5b685f38-9471-8789-5ba8-9609f1ee3484/seed/ankara_cap-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('7ccc2ec7-69b6-92f6-4686-7b91c8ab4649', '5b685f38-9471-8789-5ba8-9609f1ee3484/seed/ankara_cap-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('34caa851-e5d7-e63a-f896-430ba2773cc2', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'product'::public.listing_type, 2, 'Tall terracotta vase', 'Wheel-thrown vase, about 40 cm tall, unglazed outside.', 2800000, false, false,
    6, 'pickup'::public.delivery_mode, 'Enugu', 'Enugu', 'approved'::public.listing_status, null, now() - interval '67421 minutes', now() - interval '67421 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('34caa851-e5d7-e63a-f896-430ba2773cc2', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f/seed/clay_vase-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('34caa851-e5d7-e63a-f896-430ba2773cc2', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f/seed/clay_vase-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('e96452f5-6f54-72e9-28e1-de33907d1da6', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'product'::public.listing_type, 2, 'Set of four glazed bowls', 'Stoneware bowls in a green glaze. Food safe.', 1600000, false, false,
    10, 'delivery'::public.delivery_mode, 'Enugu', 'Enugu', 'approved'::public.listing_status, null, now() - interval '67384 minutes', now() - interval '67384 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('e96452f5-6f54-72e9-28e1-de33907d1da6', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f/seed/clay_bowls-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('e96452f5-6f54-72e9-28e1-de33907d1da6', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f/seed/clay_bowls-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('a3bf67c7-fe60-369d-6de2-54bcba3a71a7', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'product'::public.listing_type, 2, 'Hanging planter', 'Small planter with cord hanger.', 750000, false, false,
    15, 'delivery'::public.delivery_mode, 'Enugu', 'Enugu', 'approved'::public.listing_status, null, now() - interval '67347 minutes', now() - interval '67347 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('a3bf67c7-fe60-369d-6de2-54bcba3a71a7', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f/seed/clay_planter-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('a3bf67c7-fe60-369d-6de2-54bcba3a71a7', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f/seed/clay_planter-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('b9aecd1f-21a9-2df0-5cb8-a015a841c918', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'product'::public.listing_type, 2, 'Coral bead necklace', 'Three-strand coral bead necklace with brass clasp.', 3200000, false, false,
    4, 'delivery'::public.delivery_mode, 'FCT', 'Abuja', 'approved'::public.listing_status, null, now() - interval '61550 minutes', now() - interval '61550 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('b9aecd1f-21a9-2df0-5cb8-a015a841c918', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8/seed/bead_necklace-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('b9aecd1f-21a9-2df0-5cb8-a015a841c918', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8/seed/bead_necklace-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('92cea08d-873e-be12-7629-8f8b3aad9057', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'product'::public.listing_type, 2, 'Glass bead bracelet', 'Stretch bracelet in mixed glass beads.', 500000, false, false,
    30, 'delivery'::public.delivery_mode, 'FCT', 'Abuja', 'approved'::public.listing_status, null, now() - interval '61513 minutes', now() - interval '61513 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('92cea08d-873e-be12-7629-8f8b3aad9057', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8/seed/bead_bracelet-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('92cea08d-873e-be12-7629-8f8b3aad9057', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8/seed/bead_bracelet-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('dd84b5e8-e550-70ff-4944-db7c1eb7cc11', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'product'::public.listing_type, 2, 'Bridal bead set', 'Necklace, earrings and bracelet for traditional weddings.', 8500000, true, false,
    2, 'delivery'::public.delivery_mode, 'FCT', 'Abuja', 'removed'::public.listing_status, null, now() - interval '61476 minutes', now() - interval '61476 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('dd84b5e8-e550-70ff-4944-db7c1eb7cc11', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8/seed/bead_bridal-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('dd84b5e8-e550-70ff-4944-db7c1eb7cc11', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8/seed/bead_bridal-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('a53fe992-aa64-4486-852d-b2bc27361c12', 'd2f025fb-3d20-e8ca-aea7-9aef6901479b', 'product'::public.listing_type, 2, 'Lagos traffic, acrylic on canvas', 'Original painting, 60 by 90 cm.', 12000000, false, false,
    1, 'pickup'::public.delivery_mode, 'Ogun', 'Abeokuta', 'approved'::public.listing_status, null, now() - interval '54239 minutes', now() - interval '54239 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('a53fe992-aa64-4486-852d-b2bc27361c12', 'd2f025fb-3d20-e8ca-aea7-9aef6901479b/seed/canvas_lagos-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('a53fe992-aa64-4486-852d-b2bc27361c12', 'd2f025fb-3d20-e8ca-aea7-9aef6901479b/seed/canvas_lagos-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('7a9d37ca-38a9-9806-aa44-779a00b9fcc7', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'service'::public.listing_type, 5, 'Small business website', 'Five-page website with contact form and hosting set up. Delivered in two weeks.', 25000000, true, false,
    null, 'remote_service'::public.delivery_mode, 'Lagos', 'Ikeja', 'approved'::public.listing_status, null, now() - interval '65722 minutes', now() - interval '65722 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('7a9d37ca-38a9-9806-aa44-779a00b9fcc7', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0/seed/dev_website-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('93877a10-914b-4001-9a04-f875b62f7a74', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'service'::public.listing_type, 5, 'Online store setup', 'Product catalogue, cart and order emails for up to 100 products.', 45000000, true, false,
    null, 'remote_service'::public.delivery_mode, 'Lagos', 'Ikeja', 'approved'::public.listing_status, null, now() - interval '65685 minutes', now() - interval '65685 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('93877a10-914b-4001-9a04-f875b62f7a74', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0/seed/dev_store-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('db05bf6e-af57-1710-628f-be735ad31335', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'service'::public.listing_type, 5, 'Website speed check', 'Report on what slows a site down and how to fix it.', 6000000, false, false,
    null, 'remote_service'::public.delivery_mode, 'Lagos', 'Ikeja', 'pending'::public.listing_status, null, now() - interval '65648 minutes', now() - interval '65648 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('db05bf6e-af57-1710-628f-be735ad31335', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0/seed/dev_audit-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('e4793072-8918-befb-d0ff-14523ba65b3c', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'service'::public.listing_type, 5, 'Android app from your design', 'Build an Android app from Figma screens. Price depends on the number of screens.', 40000000, true, false,
    null, 'remote_service'::public.delivery_mode, 'Oyo', 'Ibadan', 'approved'::public.listing_status, null, now() - interval '49771 minutes', now() - interval '49771 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('e4793072-8918-befb-d0ff-14523ba65b3c', '8f7b4275-b407-2f4a-21f6-778871f6cb28/seed/tobi_app-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('8ae946b0-09f5-a280-af65-98a41b66e4cf', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'service'::public.listing_type, 5, 'App bug fixing, per day', 'One day of debugging and fixes on an existing Flutter app.', 4500000, false, false,
    null, 'remote_service'::public.delivery_mode, 'Oyo', 'Ibadan', 'approved'::public.listing_status, null, now() - interval '49734 minutes', now() - interval '49734 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('8ae946b0-09f5-a280-af65-98a41b66e4cf', '8f7b4275-b407-2f4a-21f6-778871f6cb28/seed/tobi_fix-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('3c06cb94-7d97-8145-a1d2-ff3eafeced3a', '84f7f7fb-6032-deba-c455-0476cb8d6c30', 'service'::public.listing_type, 5, 'Sales dashboard in Excel', 'Monthly sales dashboard built from your records.', 7500000, true, false,
    null, 'remote_service'::public.delivery_mode, 'Enugu', 'Enugu', 'approved'::public.listing_status, null, now() - interval '41057 minutes', now() - interval '41057 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('3c06cb94-7d97-8145-a1d2-ff3eafeced3a', '84f7f7fb-6032-deba-c455-0476cb8d6c30/seed/amaka_dashboard-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('91f924b7-2755-b6f0-3d3b-993b661ce8be', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'service'::public.listing_type, 3, 'Logo and brand colours', 'Three logo concepts, two rounds of changes, colour palette.', 9000000, true, false,
    null, 'remote_service'::public.delivery_mode, 'Lagos', 'Yaba', 'approved'::public.listing_status, null, now() - interval '58300 minutes', now() - interval '58300 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('91f924b7-2755-b6f0-3d3b-993b661ce8be', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34/seed/pixel_logo-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('090a9bd4-17d3-fa68-1adc-103a5c945a46', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'product'::public.listing_type, 3, 'Social media template pack', 'Thirty editable post templates. Delivered as a download.', 1500000, false, false,
    999, 'digital'::public.delivery_mode, 'Lagos', 'Yaba', 'approved'::public.listing_status, null, now() - interval '58263 minutes', now() - interval '58263 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('090a9bd4-17d3-fa68-1adc-103a5c945a46', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34/seed/pixel_templates-0.jpg', 0);
  insert into public.listing_images (listing_id, storage_path, position) values ('090a9bd4-17d3-fa68-1adc-103a5c945a46', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34/seed/pixel_templates-1.jpg', 1);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('9cf94f99-770f-c668-2945-7a207d029e56', '388fc4c1-d047-6efc-6d86-abdc0435b188', 'service'::public.listing_type, 3, 'Logo in 48 hours', 'One concept, one revision.', 2500000, false, false,
    null, 'remote_service'::public.delivery_mode, 'Kano', 'Kano', 'draft'::public.listing_status, null, now() - interval '23666 minutes', now() - interval '23666 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('9cf94f99-770f-c668-2945-7a207d029e56', '388fc4c1-d047-6efc-6d86-abdc0435b188/seed/logo_quick-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('9fceb0d5-c756-7c82-cdae-c569a1ce3e88', '730c2898-4ac5-0424-cecc-e171eae9cd23', 'service'::public.listing_type, 6, 'House rewiring', 'Full or partial rewiring. Site visit first, then a written quote.', 0, false, true,
    null, 'in_person_service'::public.delivery_mode, 'Lagos', 'Surulere', 'approved'::public.listing_status, null, now() - interval '62509 minutes', now() - interval '62509 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('9fceb0d5-c756-7c82-cdae-c569a1ce3e88', '730c2898-4ac5-0424-cecc-e171eae9cd23/seed/spark_wiring-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('a9d4ad35-0dc9-c339-a227-3d3a5beec5cb', '730c2898-4ac5-0424-cecc-e171eae9cd23', 'service'::public.listing_type, 6, 'Inverter installation', 'Install and test an inverter and battery bank.', 3500000, true, false,
    null, 'in_person_service'::public.delivery_mode, 'Lagos', 'Surulere', 'approved'::public.listing_status, null, now() - interval '62472 minutes', now() - interval '62472 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('a9d4ad35-0dc9-c339-a227-3d3a5beec5cb', '730c2898-4ac5-0424-cecc-e171eae9cd23/seed/spark_inverter-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('97b9d80a-bb7a-f47f-2c28-3a402c726dc4', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'service'::public.listing_type, 6, 'Split AC servicing', 'Clean filters and coils, check gas, per unit.', 1200000, false, false,
    null, 'in_person_service'::public.delivery_mode, 'FCT', 'Abuja', 'approved'::public.listing_status, null, now() - interval '56675 minutes', now() - interval '56675 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('97b9d80a-bb7a-f47f-2c28-3a402c726dc4', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74/seed/cool_service-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('856df9c3-701c-763d-1645-6be8d8a504c0', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'service'::public.listing_type, 6, 'AC installation', 'Install a new split unit, including bracket.', 4000000, true, false,
    null, 'in_person_service'::public.delivery_mode, 'FCT', 'Abuja', 'approved'::public.listing_status, null, now() - interval '56638 minutes', now() - interval '56638 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('856df9c3-701c-763d-1645-6be8d8a504c0', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74/seed/cool_install-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('075f9a3f-cd53-fb89-2ffb-a4244f986e29', 'b7290ec9-1c5a-32bd-9560-9d8463eee431', 'service'::public.listing_type, 6, 'Deep cleaning, three-bedroom flat', 'Two cleaners, about six hours, materials included.', 5500000, false, false,
    null, 'in_person_service'::public.delivery_mode, 'Rivers', 'Port Harcourt', 'approved'::public.listing_status, null, now() - interval '47961 minutes', now() - interval '47961 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('075f9a3f-cd53-fb89-2ffb-a4244f986e29', 'b7290ec9-1c5a-32bd-9560-9d8463eee431/seed/clean_deep-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('c2751812-feb7-f03b-68ce-a4e257eead48', 'b7290ec9-1c5a-32bd-9560-9d8463eee431', 'service'::public.listing_type, 6, 'Office cleaning, weekly', 'Weekly cleaning for small offices.', 0, false, true,
    null, 'in_person_service'::public.delivery_mode, 'Rivers', 'Port Harcourt', 'approved'::public.listing_status, null, now() - interval '47924 minutes', now() - interval '47924 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('c2751812-feb7-f03b-68ce-a4e257eead48', 'b7290ec9-1c5a-32bd-9560-9d8463eee431/seed/clean_office-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('9682cdf0-a5c3-c2d8-0593-3f7dbc76d264', '3022de0b-4a28-5e57-1148-55296124fb25', 'service'::public.listing_type, 6, 'Leaking tap and pipe repairs', 'Fix leaks, replace taps and valves.', 800000, true, false,
    null, 'in_person_service'::public.delivery_mode, 'Kaduna', 'Kaduna', 'draft'::public.listing_status, null, now() - interval '9007 minutes', now() - interval '9007 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('9682cdf0-a5c3-c2d8-0593-3f7dbc76d264', '3022de0b-4a28-5e57-1148-55296124fb25/seed/femi_plumbing-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('09251ec4-ea6f-71f0-0105-e0ade86d2a5c', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'talent'::public.listing_type, 4, 'Event photography, half day', 'Up to four hours of coverage and 150 edited photos.', 12000000, true, false,
    null, 'in_person_service'::public.delivery_mode, 'Lagos', 'Lekki', 'approved'::public.listing_status, null, now() - interval '68010 minutes', now() - interval '68010 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('09251ec4-ea6f-71f0-0105-e0ade86d2a5c', '88c5246a-1dab-e4f8-713a-e010c752dfb2/seed/lens_event-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('2d943e05-e848-04f1-d459-b9fb6a38ac33', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'talent'::public.listing_type, 4, 'Studio portrait session', 'One hour in studio, ten edited portraits.', 4000000, false, false,
    null, 'in_person_service'::public.delivery_mode, 'Lagos', 'Lekki', 'approved'::public.listing_status, null, now() - interval '67973 minutes', now() - interval '67973 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('2d943e05-e848-04f1-d459-b9fb6a38ac33', '88c5246a-1dab-e4f8-713a-e010c752dfb2/seed/lens_portrait-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('6d796ecd-d6fb-2673-26d8-241fc8edb639', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'talent'::public.listing_type, 4, 'Radio advert voice-over', 'Thirty-second advert read, two takes, broadcast quality.', 3000000, false, false,
    null, 'remote_service'::public.delivery_mode, 'Oyo', 'Ibadan', 'approved'::public.listing_status, null, now() - interval '42016 minutes', now() - interval '42016 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('6d796ecd-d6fb-2673-26d8-241fc8edb639', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2/seed/ife_advert-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('44507445-63e5-9b3a-b501-6faf997ddcde', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'talent'::public.listing_type, 4, 'Audiobook narration, per finished hour', 'Narration and basic editing.', 7000000, true, false,
    null, 'remote_service'::public.delivery_mode, 'Oyo', 'Ibadan', 'approved'::public.listing_status, null, now() - interval '41979 minutes', now() - interval '41979 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('44507445-63e5-9b3a-b501-6faf997ddcde', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2/seed/ife_audiobook-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('8fe890b4-d7c8-47d0-dde4-49a1877c5a94', '19d2c070-1501-1c48-da57-d74352bbde02', 'talent'::public.listing_type, 4, 'Live band for weddings', 'Three hours of highlife and talking drum.', 30000000, true, false,
    null, 'in_person_service'::public.delivery_mode, 'Lagos', 'Ikeja', 'approved'::public.listing_status, null, now() - interval '34742 minutes', now() - interval '34742 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('8fe890b4-d7c8-47d0-dde4-49a1877c5a94', '19d2c070-1501-1c48-da57-d74352bbde02/seed/drum_wedding-0.jpg', 0);
  insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,
    stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)
  values ('b3e3d48b-e6bf-c1a9-4d2a-061fbc737cfe', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'talent'::public.listing_type, 4, 'MC for parties', 'Bilingual MC, up to five hours.', 8000000, true, false,
    null, 'in_person_service'::public.delivery_mode, 'Lagos', 'Surulere', 'approved'::public.listing_status, null, now() - interval '20305 minutes', now() - interval '20305 minutes');
  insert into public.listing_images (listing_id, storage_path, position) values ('b3e3d48b-e6bf-c1a9-4d2a-061fbc737cfe', 'fabae036-2d8c-f09e-cbd7-101d945f64a0/seed/kunle_mc-0.jpg', 0);

  -- 5. Home-service areas and hours; professional page entries
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('3fd6c6ea-9c39-f1cb-ca73-42382088c2b4', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'experience'::public.pro_entry_kind, 'Lead at DevCraft Studio', 'DevCraft Studio', 'Ikeja', 2018, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('55e9eb9b-a001-2700-706b-4ec3a406e4f3', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Lagos', 2015, 2018, false, null, 1);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('6ca46546-3e8c-e755-29b2-71e9a4796b1a', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'certification'::public.pro_entry_kind, 'Seed cloud practitioner certificate', 'Seed Training Centre', null, 2025, 2025, false, null, 2);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('b77a3087-27de-4131-0bd0-297c4a7b22b7', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'experience'::public.pro_entry_kind, 'Lead at Tobi (seed freelancer)', 'Tobi (seed freelancer)', 'Ibadan', 2021, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('8740f2eb-dab5-0088-bce1-14a75a6b405f', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Oyo', 2018, 2021, false, null, 1);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('94f1e6aa-ce59-0eea-3658-f10b8c33c79b', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'certification'::public.pro_entry_kind, 'Seed cloud practitioner certificate', 'Seed Training Centre', null, 2025, 2025, false, null, 2);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('c6b93d2f-07be-c92d-6aff-b7ee754836d9', '84f7f7fb-6032-deba-c455-0476cb8d6c30', 'experience'::public.pro_entry_kind, 'Lead at Amaka Data', 'Amaka Data', 'Enugu', 2022, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('0a3e16d4-1d07-f3be-5434-961d501dc9ee', '84f7f7fb-6032-deba-c455-0476cb8d6c30', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Enugu', 2019, 2022, false, null, 1);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('5c97a49e-c020-cf45-16e3-0b92f821db32', '84f7f7fb-6032-deba-c455-0476cb8d6c30', 'certification'::public.pro_entry_kind, 'Seed cloud practitioner certificate', 'Seed Training Centre', null, 2025, 2025, false, null, 2);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('1fdc6d36-b19f-d52d-b523-1776acb60e9b', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'experience'::public.pro_entry_kind, 'Lead at Pixel Forge', 'Pixel Forge', 'Yaba', 2020, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('2381aaca-e01f-c9ce-1643-7e90f0874e2e', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Lagos', 2017, 2020, false, null, 1);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('fec50b25-50d1-8911-12b9-6e4141451724', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'certification'::public.pro_entry_kind, 'Seed cloud practitioner certificate', 'Seed Training Centre', null, 2025, 2025, false, null, 2);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('45c7755d-a781-7208-e8e0-86e9f92dad7b', '388fc4c1-d047-6efc-6d86-abdc0435b188', 'experience'::public.pro_entry_kind, 'Lead at Logo Lab', 'Logo Lab', 'Kano', 2023, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('76016512-b572-5a74-fda4-b04a1ed3c965', '388fc4c1-d047-6efc-6d86-abdc0435b188', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Kano', 2020, 2023, false, null, 1);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('09d5527a-2441-3f85-96de-2f17db71932f', '388fc4c1-d047-6efc-6d86-abdc0435b188', 'certification'::public.pro_entry_kind, 'Seed cloud practitioner certificate', 'Seed Training Centre', null, 2025, 2025, false, null, 2);
  insert into public.service_areas (seller_id, state, city) values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 'Lagos', 'Surulere');
  insert into public.service_areas (seller_id, state, city) values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 'Lagos', 'Ikeja');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 1, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 2, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 3, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 4, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 5, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('730c2898-4ac5-0424-cecc-e171eae9cd23', 6, '08:00', '14:00');
  insert into public.service_areas (seller_id, state, city) values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'FCT', 'Abuja');
  insert into public.service_areas (seller_id, state, city) values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'FCT', 'Gwarinpa');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 1, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 2, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 3, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 4, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 5, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 6, '08:00', '14:00');
  insert into public.service_areas (seller_id, state, city) values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 'Rivers', 'Port Harcourt');
  insert into public.service_areas (seller_id, state, city) values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 'Rivers', 'Obio-Akpor');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 1, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 2, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 3, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 4, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 5, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('b7290ec9-1c5a-32bd-9560-9d8463eee431', 6, '08:00', '14:00');
  insert into public.service_areas (seller_id, state, city) values ('3022de0b-4a28-5e57-1148-55296124fb25', 'Kaduna', 'Kaduna');
  insert into public.service_areas (seller_id, state, city) values ('3022de0b-4a28-5e57-1148-55296124fb25', 'Kaduna', 'Zaria');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('3022de0b-4a28-5e57-1148-55296124fb25', 1, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('3022de0b-4a28-5e57-1148-55296124fb25', 2, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('3022de0b-4a28-5e57-1148-55296124fb25', 3, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('3022de0b-4a28-5e57-1148-55296124fb25', 4, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('3022de0b-4a28-5e57-1148-55296124fb25', 5, '08:00', '18:00');
  insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ('3022de0b-4a28-5e57-1148-55296124fb25', 6, '08:00', '14:00');
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('4d0ada2d-857d-31f8-19e6-231857e02dd5', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'experience'::public.pro_entry_kind, 'Lead at Lens and Light', 'Lens and Light', 'Lekki', 2017, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('15a8f5b3-550f-c875-5a5d-2c21b85efc2b', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Lagos', 2014, 2017, false, null, 1);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('ab18fef1-79af-d704-f6a5-a2f1d82a3adb', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'experience'::public.pro_entry_kind, 'Lead at Voice by Ife', 'Voice by Ife', 'Ibadan', 2020, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('ccfaa9a6-2f40-d1af-fe18-8fa02f8aa572', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Oyo', 2017, 2020, false, null, 1);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('bbcedcc1-bc03-5cb7-71c6-2a9435e5a3e8', '19d2c070-1501-1c48-da57-d74352bbde02', 'experience'::public.pro_entry_kind, 'Lead at Drum Circle Band', 'Drum Circle Band', 'Ikeja', 2015, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('9f72539b-ffcf-f3b2-1ed2-7ed123a7059d', '19d2c070-1501-1c48-da57-d74352bbde02', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Lagos', 2012, 2015, false, null, 1);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('4cb2e1aa-b6fa-a2e1-c746-e7a2a97f7540', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'experience'::public.pro_entry_kind, 'Lead at MC Kunle', 'MC Kunle', 'Surulere', 2019, null, true, 'Running client projects end to end.', 0);
  insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)
  values ('90d37a10-bb81-f7f1-acab-828bd0156ecb', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'education'::public.pro_entry_kind, 'Diploma, applied arts and technology', 'Seed Polytechnic', 'Lagos', 2016, 2019, false, null, 1);

  -- 6. Purple Stories (video files are placeholders), tagged products, likes, comments, events
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('72ef1791-fc3d-5eb9-82f9-b11e4319664c', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'Dyeing a fresh batch of indigo', 'From the dye pot to the drying line.', 1, '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/st_adire1.mp4', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/st_adire1.jpg', 34, 8592031,
    720, 1280, 'published'::public.story_status, null, 111, now() - interval '14700 minutes', now() - interval '14700 minutes', now() - interval '14700 minutes');
  insert into public.story_video_products (video_id, listing_id, position) values ('72ef1791-fc3d-5eb9-82f9-b11e4319664c', '5dd229ee-4840-ce1f-fb95-c9e949052242', 0);
  insert into public.story_video_products (video_id, listing_id, position) values ('72ef1791-fc3d-5eb9-82f9-b11e4319664c', 'c9e2cb72-935a-32fa-b317-4b23ab198d39', 1);
  insert into public.story_likes (video_id, user_id) values ('72ef1791-fc3d-5eb9-82f9-b11e4319664c', '078cf7cd-d43e-8909-4e82-3a8f54700ba4');
  insert into public.story_likes (video_id, user_id) values ('72ef1791-fc3d-5eb9-82f9-b11e4319664c', '0b247d05-4c2d-3855-10ca-1ac40c298aca');
  insert into public.story_likes (video_id, user_id) values ('72ef1791-fc3d-5eb9-82f9-b11e4319664c', 'c6f897e2-0390-b115-2cf3-2871fcac34ba');
  insert into public.story_likes (video_id, user_id) values ('72ef1791-fc3d-5eb9-82f9-b11e4319664c', '1552c7e1-cc9c-93b7-ba81-3020842f3191');
  insert into public.story_likes (video_id, user_id) values ('72ef1791-fc3d-5eb9-82f9-b11e4319664c', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2');
  insert into public.story_events (video_id, event_type, created_at) select '72ef1791-fc3d-5eb9-82f9-b11e4319664c', 'impression'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '72ef1791-fc3d-5eb9-82f9-b11e4319664c', 'view'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 27) g;
  insert into public.story_events (video_id, event_type, created_at) select '72ef1791-fc3d-5eb9-82f9-b11e4319664c', 'product_click'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 3) g;
  insert into public.story_events (video_id, event_type, created_at) select '72ef1791-fc3d-5eb9-82f9-b11e4319664c', 'shop_visit'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 2) g;
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('486236f3-6bd2-21b0-d98f-a0b96145eddd', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'Three ways to tie an adire wrapper', 'Quick styling ideas.', 1, '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/st_adire2.mp4', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729/seed/st_adire2.jpg', 48, 12129927,
    720, 1280, 'published'::public.story_status, null, 259, now() - interval '13260 minutes', now() - interval '13260 minutes', now() - interval '13260 minutes');
  insert into public.story_video_products (video_id, listing_id, position) values ('486236f3-6bd2-21b0-d98f-a0b96145eddd', '5dd229ee-4840-ce1f-fb95-c9e949052242', 0);
  insert into public.story_likes (video_id, user_id) values ('486236f3-6bd2-21b0-d98f-a0b96145eddd', '0b247d05-4c2d-3855-10ca-1ac40c298aca');
  insert into public.story_likes (video_id, user_id) values ('486236f3-6bd2-21b0-d98f-a0b96145eddd', '1552c7e1-cc9c-93b7-ba81-3020842f3191');
  insert into public.story_likes (video_id, user_id) values ('486236f3-6bd2-21b0-d98f-a0b96145eddd', '0f89d922-f179-c83a-4035-7269ab41815d');
  insert into public.story_likes (video_id, user_id) values ('486236f3-6bd2-21b0-d98f-a0b96145eddd', '078cf7cd-d43e-8909-4e82-3a8f54700ba4');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('1e02abfd-f439-d9d0-c0ff-59c9f27d561e', '486236f3-6bd2-21b0-d98f-a0b96145eddd', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'Do you deliver to Abuja?', now() - interval '11520 minutes');
  insert into public.story_events (video_id, event_type, created_at) select '486236f3-6bd2-21b0-d98f-a0b96145eddd', 'impression'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '486236f3-6bd2-21b0-d98f-a0b96145eddd', 'view'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '486236f3-6bd2-21b0-d98f-a0b96145eddd', 'product_click'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 3) g;
  insert into public.story_events (video_id, event_type, created_at) select '486236f3-6bd2-21b0-d98f-a0b96145eddd', 'shop_visit'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 2) g;
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', '065cae22-135c-dc6a-d539-8cfc70565d94', 'New kampala colours this week', 'Orange, teal and purple batches.', 1, '065cae22-135c-dc6a-d539-8cfc70565d94/seed/st_kampala.mp4', '065cae22-135c-dc6a-d539-8cfc70565d94/seed/st_kampala.jpg', 22, 5559549,
    720, 1280, 'published'::public.story_status, null, 52, now() - interval '11820 minutes', now() - interval '11820 minutes', now() - interval '11820 minutes');
  insert into public.story_video_products (video_id, listing_id, position) values ('c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', '5bc541dd-6d66-1b2e-f2be-1fb6e7ba6c2c', 0);
  insert into public.story_video_products (video_id, listing_id, position) values ('c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', '65003b04-4337-0ee0-54a7-8af5dc80cbdf', 1);
  insert into public.story_likes (video_id, user_id) values ('c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', 'c6f897e2-0390-b115-2cf3-2871fcac34ba');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('3ffa35bd-37c2-f7ad-eba7-e8e007f4da96', 'c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'The colours are beautiful.', now() - interval '10080 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('d74935c4-7741-e0f3-2c93-d5f47c6ceece', 'c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'How long does this take?', now() - interval '10080 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('d7ab3758-595b-5e56-f206-0ff0f95a4001', 'c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'Lovely work!', now() - interval '10080 minutes');
  insert into public.story_events (video_id, event_type, created_at) select 'c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', 'impression'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select 'c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', 'view'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 13) g;
  insert into public.story_events (video_id, event_type, created_at) select 'c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', 'product_click'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 3) g;
  insert into public.story_events (video_id, event_type, created_at) select 'c67f19fa-ab5a-d2cf-7a60-70a80f5c7741', 'shop_visit'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 2) g;
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('89d4d03e-2047-c41d-abff-31278c5c124b', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'Throwing a vase on the wheel', 'Ten minutes, sped up.', 2, '1734e54e-6df3-bd1b-3a18-07309e3d2c2f/seed/st_clay.mp4', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f/seed/st_clay.jpg', 55, 13898874,
    720, 1280, 'published'::public.story_status, null, 246, now() - interval '10380 minutes', now() - interval '10380 minutes', now() - interval '10380 minutes');
  insert into public.story_video_products (video_id, listing_id, position) values ('89d4d03e-2047-c41d-abff-31278c5c124b', '34caa851-e5d7-e63a-f896-430ba2773cc2', 0);
  insert into public.story_video_products (video_id, listing_id, position) values ('89d4d03e-2047-c41d-abff-31278c5c124b', 'e96452f5-6f54-72e9-28e1-de33907d1da6', 1);
  insert into public.story_likes (video_id, user_id) values ('89d4d03e-2047-c41d-abff-31278c5c124b', '2b7d6168-fb32-2091-6848-977c9ebe9666');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('d0207c76-9404-9f06-b50a-88d27139e011', '89d4d03e-2047-c41d-abff-31278c5c124b', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'How long does this take?', now() - interval '8640 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('658f85be-790d-4fde-d060-ba0074be15df', '89d4d03e-2047-c41d-abff-31278c5c124b', '0b247d05-4c2d-3855-10ca-1ac40c298aca', 'Lovely work!', now() - interval '8640 minutes');
  insert into public.story_events (video_id, event_type, created_at) select '89d4d03e-2047-c41d-abff-31278c5c124b', 'impression'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '89d4d03e-2047-c41d-abff-31278c5c124b', 'view'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '89d4d03e-2047-c41d-abff-31278c5c124b', 'product_click'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 3) g;
  insert into public.story_events (video_id, event_type, created_at) select '89d4d03e-2047-c41d-abff-31278c5c124b', 'shop_visit'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 2) g;
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('66ec67a5-8850-5fad-e3d9-a2b2d4a61814', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'Stringing a coral necklace', 'Close-up of the knotting.', 2, '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8/seed/st_bead.mp4', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8/seed/st_bead.jpg', 41, 10360979,
    720, 1280, 'published'::public.story_status, null, 344, now() - interval '8940 minutes', now() - interval '8940 minutes', now() - interval '8940 minutes');
  insert into public.story_video_products (video_id, listing_id, position) values ('66ec67a5-8850-5fad-e3d9-a2b2d4a61814', 'b9aecd1f-21a9-2df0-5cb8-a015a841c918', 0);
  insert into public.story_likes (video_id, user_id) values ('66ec67a5-8850-5fad-e3d9-a2b2d4a61814', '2b7d6168-fb32-2091-6848-977c9ebe9666');
  insert into public.story_likes (video_id, user_id) values ('66ec67a5-8850-5fad-e3d9-a2b2d4a61814', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('00adace5-bdef-c38a-7a30-88ce888199f0', '66ec67a5-8850-5fad-e3d9-a2b2d4a61814', '0b247d05-4c2d-3855-10ca-1ac40c298aca', 'Lovely work!', now() - interval '7200 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('e528368d-6c4b-3609-454d-a1fb41b3f528', '66ec67a5-8850-5fad-e3d9-a2b2d4a61814', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'Do you deliver to Abuja?', now() - interval '7200 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('a0ada8f4-a0de-5ebe-769f-94959d496017', '66ec67a5-8850-5fad-e3d9-a2b2d4a61814', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'The colours are beautiful.', now() - interval '7200 minutes');
  insert into public.story_events (video_id, event_type, created_at) select '66ec67a5-8850-5fad-e3d9-a2b2d4a61814', 'impression'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '66ec67a5-8850-5fad-e3d9-a2b2d4a61814', 'view'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '66ec67a5-8850-5fad-e3d9-a2b2d4a61814', 'product_click'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 3) g;
  insert into public.story_events (video_id, event_type, created_at) select '66ec67a5-8850-5fad-e3d9-a2b2d4a61814', 'shop_visit'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 2) g;
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('f61cbbb9-9aed-8a58-0cf0-5f481f274a15', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'Behind the scenes at a naming ceremony', 'Lighting set-up for indoor events.', 4, '88c5246a-1dab-e4f8-713a-e010c752dfb2/seed/st_lens1.mp4', '88c5246a-1dab-e4f8-713a-e010c752dfb2/seed/st_lens1.jpg', 30, 7581204,
    720, 1280, 'published'::public.story_status, null, 121, now() - interval '7500 minutes', now() - interval '7500 minutes', now() - interval '7500 minutes');
  insert into public.story_likes (video_id, user_id) values ('f61cbbb9-9aed-8a58-0cf0-5f481f274a15', '0f89d922-f179-c83a-4035-7269ab41815d');
  insert into public.story_likes (video_id, user_id) values ('f61cbbb9-9aed-8a58-0cf0-5f481f274a15', '078cf7cd-d43e-8909-4e82-3a8f54700ba4');
  insert into public.story_likes (video_id, user_id) values ('f61cbbb9-9aed-8a58-0cf0-5f481f274a15', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747');
  insert into public.story_likes (video_id, user_id) values ('f61cbbb9-9aed-8a58-0cf0-5f481f274a15', '2b7d6168-fb32-2091-6848-977c9ebe9666');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('8392e70f-1210-288d-c904-2ed111db068a', 'f61cbbb9-9aed-8a58-0cf0-5f481f274a15', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'Do you deliver to Abuja?', now() - interval '5760 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('f83520d3-17cb-9102-efcc-77b6aab2e207', 'f61cbbb9-9aed-8a58-0cf0-5f481f274a15', '2b7d6168-fb32-2091-6848-977c9ebe9666', 'The colours are beautiful.', now() - interval '5760 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('f12f01f4-08d6-6ead-ff7e-0e1d75762c38', 'f61cbbb9-9aed-8a58-0cf0-5f481f274a15', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'How long does this take?', now() - interval '5760 minutes');
  insert into public.story_events (video_id, event_type, created_at) select 'f61cbbb9-9aed-8a58-0cf0-5f481f274a15', 'impression'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select 'f61cbbb9-9aed-8a58-0cf0-5f481f274a15', 'view'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 30) g;
  insert into public.story_events (video_id, event_type, created_at) select 'f61cbbb9-9aed-8a58-0cf0-5f481f274a15', 'shop_visit'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 2) g;
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('f4211122-4191-3802-71a4-71a7756b2a37', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'Before and after: portrait edit', 'Colour grading a studio portrait.', 4, '88c5246a-1dab-e4f8-713a-e010c752dfb2/seed/st_lens2.mp4', '88c5246a-1dab-e4f8-713a-e010c752dfb2/seed/st_lens2.jpg', 19, 4801429,
    720, 1280, 'published'::public.story_status, null, 190, now() - interval '6060 minutes', now() - interval '6060 minutes', now() - interval '6060 minutes');
  insert into public.story_likes (video_id, user_id) values ('f4211122-4191-3802-71a4-71a7756b2a37', '0f89d922-f179-c83a-4035-7269ab41815d');
  insert into public.story_likes (video_id, user_id) values ('f4211122-4191-3802-71a4-71a7756b2a37', 'f6d2c74a-a808-09cc-0aca-251d36d2d751');
  insert into public.story_likes (video_id, user_id) values ('f4211122-4191-3802-71a4-71a7756b2a37', '078cf7cd-d43e-8909-4e82-3a8f54700ba4');
  insert into public.story_likes (video_id, user_id) values ('f4211122-4191-3802-71a4-71a7756b2a37', '1552c7e1-cc9c-93b7-ba81-3020842f3191');
  insert into public.story_likes (video_id, user_id) values ('f4211122-4191-3802-71a4-71a7756b2a37', '0b247d05-4c2d-3855-10ca-1ac40c298aca');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('3df0b38d-cf33-81d9-18d1-2e37f58fecfc', 'f4211122-4191-3802-71a4-71a7756b2a37', '1552c7e1-cc9c-93b7-ba81-3020842f3191', 'The colours are beautiful.', now() - interval '4320 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('73a3b0ca-0a48-111c-1f52-7061ea30ba04', 'f4211122-4191-3802-71a4-71a7756b2a37', '2b7d6168-fb32-2091-6848-977c9ebe9666', 'How long does this take?', now() - interval '4320 minutes');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('e5df29d0-ce0c-25f8-d6b5-37d9cffc7503', 'f4211122-4191-3802-71a4-71a7756b2a37', '0b247d05-4c2d-3855-10ca-1ac40c298aca', 'Lovely work!', now() - interval '4320 minutes');
  insert into public.story_events (video_id, event_type, created_at) select 'f4211122-4191-3802-71a4-71a7756b2a37', 'impression'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select 'f4211122-4191-3802-71a4-71a7756b2a37', 'view'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 47) g;
  insert into public.story_events (video_id, event_type, created_at) select 'f4211122-4191-3802-71a4-71a7756b2a37', 'shop_visit'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 2) g;
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('99c46f51-10d4-c80d-569b-431163a08ba9', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'Packaging design for a juice brand', 'Sketch to final box.', 3, 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34/seed/st_pixel.mp4', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34/seed/st_pixel.jpg', 27, 6823084,
    720, 1280, 'published'::public.story_status, null, 286, now() - interval '4620 minutes', now() - interval '4620 minutes', now() - interval '4620 minutes');
  insert into public.story_likes (video_id, user_id) values ('99c46f51-10d4-c80d-569b-431163a08ba9', '078cf7cd-d43e-8909-4e82-3a8f54700ba4');
  insert into public.story_likes (video_id, user_id) values ('99c46f51-10d4-c80d-569b-431163a08ba9', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747');
  insert into public.story_likes (video_id, user_id) values ('99c46f51-10d4-c80d-569b-431163a08ba9', '0b247d05-4c2d-3855-10ca-1ac40c298aca');
  insert into public.story_comments (id, video_id, user_id, body, created_at) values ('85a88812-9189-85d3-5e84-2b443758da11', '99c46f51-10d4-c80d-569b-431163a08ba9', '0b247d05-4c2d-3855-10ca-1ac40c298aca', 'How long does this take?', now() - interval '2880 minutes');
  insert into public.story_events (video_id, event_type, created_at) select '99c46f51-10d4-c80d-569b-431163a08ba9', 'impression'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '99c46f51-10d4-c80d-569b-431163a08ba9', 'view'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 60) g;
  insert into public.story_events (video_id, event_type, created_at) select '99c46f51-10d4-c80d-569b-431163a08ba9', 'shop_visit'::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, 2) g;
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('37bc139a-5476-734d-b327-e836aaf415dc', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'Voice-over demo reel', 'Advert, documentary and audiobook samples.', 4, 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2/seed/st_ife.mp4', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2/seed/st_ife.jpg', 58, 14656995,
    720, 1280, 'draft'::public.story_status, null, 0, null, now() - interval '3180 minutes', now() - interval '3180 minutes');
  insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,
    width, height, status, moderation_note, view_count, published_at, created_at, updated_at)
  values ('12ceebdd-b119-5538-503c-92f48de35403', '19d2c070-1501-1c48-da57-d74352bbde02', 'Wedding band highlights', 'Hidden by moderation for a test case.', 4, '19d2c070-1501-1c48-da57-d74352bbde02/seed/st_drum.mp4', '19d2c070-1501-1c48-da57-d74352bbde02/seed/st_drum.jpg', 45, 11371806,
    720, 1280, 'hidden'::public.story_status, 'Seed: hidden after a test report.', 0, now() - interval '1740 minutes', now() - interval '1740 minutes', now() - interval '1740 minutes');

  -- 7. Purple Requests and offers
  insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)
  values ('40218982-dc78-2797-e92d-f933c000185f', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 5, 'Website for a small bakery', 'Menu, opening hours and an order form. Budget is flexible for the right designer.', 30000000, 'Lagos', 'Ikeja', 'open'::public.request_status, now() - interval '7200 minutes', now() + interval '12960 minutes', null, now() - interval '7200 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('219bd8b4-9895-fb9a-90a1-a972b3708646', '40218982-dc78-2797-e92d-f933c000185f', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'We can deliver a five-page site with an order form in two weeks.', 28000000, 14, 'sent'::public.offer_status, now() - interval '7080 minutes', now() - interval '7080 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('04018815-e62f-a9c1-88e5-11262d35745e', '40218982-dc78-2797-e92d-f933c000185f', '8f7b4275-b407-2f4a-21f6-778871f6cb28', 'Happy to build this with a simple admin page.', 25000000, 21, 'sent'::public.offer_status, now() - interval '7020 minutes', now() - interval '7020 minutes');
  update public.buyer_requests set offer_count = 2, accepted_offer_id = null where id = '40218982-dc78-2797-e92d-f933c000185f';
  insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)
  values ('77df6900-7a6c-ba66-81f5-dddc0199c6b2', '0f89d922-f179-c83a-4035-7269ab41815d', 1, 'Custom adire outfit for a wedding', 'Matching outfits for four people, indigo with white patterns.', 16000000, 'Lagos', 'Yaba', 'open'::public.request_status, now() - interval '5760 minutes', now() + interval '14400 minutes', null, now() - interval '5760 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('f21612b2-ef6d-d7e3-6fae-f405ce556078', '77df6900-7a6c-ba66-81f5-dddc0199c6b2', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'Four outfits in ten days. We can share fabric samples first.', 15000000, 10, 'sent'::public.offer_status, now() - interval '5640 minutes', now() - interval '5640 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('15c2b231-cbe8-54e6-3be2-b07b3dc082b1', '77df6900-7a6c-ba66-81f5-dddc0199c6b2', '065cae22-135c-dc6a-d539-8cfc70565d94', 'We can do this in kampala instead of adire.', 12000000, 14, 'declined'::public.offer_status, now() - interval '5580 minutes', now() - interval '5580 minutes');
  update public.buyer_requests set offer_count = 1, accepted_offer_id = null where id = '77df6900-7a6c-ba66-81f5-dddc0199c6b2';
  insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)
  values ('7d422983-7736-082b-b1f0-7a9f05428653', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 6, 'AC servicing for two split units', 'Both units cool slowly. Flat in Garki.', 3000000, 'Enugu', 'Enugu', 'closed'::public.request_status, now() - interval '12960 minutes', now() + interval '7200 minutes', now() - interval '10080 minutes', now() - interval '12960 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('6f9853bb-4d93-5315-8a35-d8e7bffaac00', '7d422983-7736-082b-b1f0-7a9f05428653', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'Servicing for both units with a gas check, this week.', 2400000, 2, 'accepted'::public.offer_status, now() - interval '12840 minutes', now() - interval '12840 minutes');
  update public.buyer_requests set offer_count = 1, accepted_offer_id = '6f9853bb-4d93-5315-8a35-d8e7bffaac00' where id = '7d422983-7736-082b-b1f0-7a9f05428653';
  insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)
  values ('3f114935-49c3-6dc9-e0f8-494e9bfe0593', '0b247d05-4c2d-3855-10ca-1ac40c298aca', 3, 'Logo and brand colours for a new shop', 'Grocery shop opening next month.', 8000000, 'Kano', 'Kano', 'open'::public.request_status, now() - interval '10080 minutes', now() + interval '10080 minutes', null, now() - interval '10080 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('d0830222-ebe3-2cd2-efac-05aa621c7353', '3f114935-49c3-6dc9-e0f8-494e9bfe0593', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34', 'Three concepts and a colour palette within a week.', 9000000, 7, 'sent'::public.offer_status, now() - interval '9960 minutes', now() - interval '9960 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('1ea3ff05-64db-3f7d-270c-dd9a89ba7575', '3f114935-49c3-6dc9-e0f8-494e9bfe0593', '388fc4c1-d047-6efc-6d86-abdc0435b188', 'Quick logo option.', 2500000, 2, 'withdrawn'::public.offer_status, now() - interval '9900 minutes', now() - interval '9900 minutes');
  update public.buyer_requests set offer_count = 1, accepted_offer_id = null where id = '3f114935-49c3-6dc9-e0f8-494e9bfe0593';
  insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)
  values ('58ddcb65-10ac-4b78-dbea-3e221122aa52', '1552c7e1-cc9c-93b7-ba81-3020842f3191', 4, 'Photographer for a naming ceremony', 'Saturday morning, about three hours, Ibadan.', 10000000, 'Oyo', 'Ibadan', 'open'::public.request_status, now() - interval '4320 minutes', now() + interval '15840 minutes', null, now() - interval '4320 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('65211882-92ed-eaf7-e64e-1f7ccd7f9574', '58ddcb65-10ac-4b78-dbea-3e221122aa52', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'Half-day coverage with edited photos within a week.', 11000000, 1, 'sent'::public.offer_status, now() - interval '4200 minutes', now() - interval '4200 minutes');
  update public.buyer_requests set offer_count = 1, accepted_offer_id = null where id = '58ddcb65-10ac-4b78-dbea-3e221122aa52';
  insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)
  values ('2dd9b235-09c0-aae4-9e2e-f6ef8195ae9c', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', 6, 'Deep cleaning after renovation', 'Four-bedroom house, dust everywhere.', 7000000, 'Rivers', 'Port Harcourt', 'expired'::public.request_status, now() - interval '28800 minutes', now() - interval '8640 minutes', null, now() - interval '28800 minutes');
  update public.buyer_requests set offer_count = 0, accepted_offer_id = null where id = '2dd9b235-09c0-aae4-9e2e-f6ef8195ae9c';
  insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)
  values ('0c80ebfd-d5c0-1f0a-016b-0d608df1b1cb', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 4, 'MC for a birthday party', 'Evening party for about eighty guests.', 6000000, 'FCT', 'Abuja', 'closed'::public.request_status, now() - interval '17280 minutes', now() + interval '2880 minutes', now() - interval '14400 minutes', now() - interval '17280 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('ad702758-5e3f-29ff-6fab-5593df4d48c7', '0c80ebfd-d5c0-1f0a-016b-0d608df1b1cb', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'Five hours of hosting, bilingual.', 8000000, 1, 'declined'::public.offer_status, now() - interval '17160 minutes', now() - interval '17160 minutes');
  update public.buyer_requests set offer_count = 0, accepted_offer_id = null where id = '0c80ebfd-d5c0-1f0a-016b-0d608df1b1cb';
  insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)
  values ('0582abed-d729-a640-5f32-83261d87f537', '2b7d6168-fb32-2091-6848-977c9ebe9666', 2, 'Handmade clay vases for an office', 'Six medium vases for a reception area.', 15000000, 'Lagos', 'Surulere', 'open'::public.request_status, now() - interval '2880 minutes', now() + interval '17280 minutes', null, now() - interval '2880 minutes');
  insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)
  values ('0d0ecce9-349e-cad5-466f-86303451bd9d', '0582abed-d729-a640-5f32-83261d87f537', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'Six vases in a matching glaze, ready in twelve days.', 14000000, 12, 'sent'::public.offer_status, now() - interval '2760 minutes', now() - interval '2760 minutes');
  update public.buyer_requests set offer_count = 1, accepted_offer_id = null where id = '0582abed-d729-a640-5f32-83261d87f537';

  -- 8. Conversations and messages
  insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)
  values ('c0fb998d-b48f-40ce-5860-2eadd2c3bb90', '0f89d922-f179-c83a-4035-7269ab41815d', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'c9e2cb72-935a-32fa-b317-4b23ab198d39', null, now() - interval '17280 minutes', now() - interval '17250 minutes', now() - interval '17250 minutes', now() - interval '17255 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('c3fbbed9-6c30-1ce8-4180-57c976bf660d', 'c0fb998d-b48f-40ce-5860-2eadd2c3bb90', '0f89d922-f179-c83a-4035-7269ab41815d', 'Hello, is the adire shirt available in size L?', now() - interval '17278 minutes', now() - interval '17280 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('682e7196-de43-4d3a-c4b7-1bb0ee779582', 'c0fb998d-b48f-40ce-5860-2eadd2c3bb90', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'Yes, we have L. It takes five working days.', now() - interval '17268 minutes', now() - interval '17270 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('5fee9486-beac-b161-c9c4-a6ab8f556b98', 'c0fb998d-b48f-40ce-5860-2eadd2c3bb90', '0f89d922-f179-c83a-4035-7269ab41815d', 'Great, I will order through the site today.', now() - interval '17258 minutes', now() - interval '17260 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('b9f6f2bb-104e-1e5c-2d5c-537173c13ab4', 'c0fb998d-b48f-40ce-5860-2eadd2c3bb90', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'Thank you! We will start once the order comes in.', null, now() - interval '17250 minutes');
  insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)
  values ('131732fb-08c1-032f-23e3-6d0f8e8e9bfa', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', '7a9d37ca-38a9-9806-aa44-779a00b9fcc7', null, now() - interval '15840 minutes', now() - interval '15830 minutes', now() - interval '15830 minutes', now() - interval '15830 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('ec36bae6-2e83-eb13-a687-feb19c6db160', '131732fb-08c1-032f-23e3-6d0f8e8e9bfa', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'Can the website include an online menu?', now() - interval '15838 minutes', now() - interval '15840 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('585e6a19-7bc6-e7e3-c17d-6d9d4e6af849', '131732fb-08c1-032f-23e3-6d0f8e8e9bfa', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'Yes, the menu can be edited from a simple admin page.', now() - interval '15828 minutes', now() - interval '15830 minutes');
  insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)
  values ('4b22aea3-de1f-b594-ff96-e2c297057b1b', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', null, '6f9853bb-4d93-5315-8a35-d8e7bffaac00', now() - interval '14400 minutes', now() - interval '14370 minutes', now() - interval '14370 minutes', now() - interval '14370 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('42162694-eb15-32c4-2179-0e771c425a61', '4b22aea3-de1f-b594-ff96-e2c297057b1b', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'Thanks for accepting. Which day works for you?', now() - interval '14398 minutes', now() - interval '14400 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('42a7e888-7714-9b34-dfa8-f08a903b1d6a', '4b22aea3-de1f-b594-ff96-e2c297057b1b', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'Thursday afternoon is best.', now() - interval '14388 minutes', now() - interval '14390 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('7eb05ee9-f785-44f2-4060-d6830f84909d', '4b22aea3-de1f-b594-ff96-e2c297057b1b', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', 'Thursday afternoon is booked. See you then.', now() - interval '14378 minutes', now() - interval '14380 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('11f5207d-0463-a1ea-6bc9-aa8657d7c229', '4b22aea3-de1f-b594-ff96-e2c297057b1b', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'Perfect, thank you.', now() - interval '14368 minutes', now() - interval '14370 minutes');
  insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)
  values ('7c2433f7-f650-0d65-b404-ee5e869b699d', '1552c7e1-cc9c-93b7-ba81-3020842f3191', '88c5246a-1dab-e4f8-713a-e010c752dfb2', '09251ec4-ea6f-71f0-0105-e0ade86d2a5c', null, now() - interval '12960 minutes', now() - interval '12950 minutes', now() - interval '12950 minutes', now() - interval '12955 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('dd9cde60-9230-df8c-a424-1f5bfcff05a9', '7c2433f7-f650-0d65-b404-ee5e869b699d', '1552c7e1-cc9c-93b7-ba81-3020842f3191', 'Do you also cover the evening reception?', now() - interval '12958 minutes', now() - interval '12960 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('d217f10c-1242-c7cd-e5b6-af8a5628297a', '7c2433f7-f650-0d65-b404-ee5e869b699d', '88c5246a-1dab-e4f8-713a-e010c752dfb2', 'Yes, we can extend to a full day for an extra fee.', null, now() - interval '12950 minutes');
  insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)
  values ('5364cec5-4b93-658a-9fe9-c5f618689935', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'e96452f5-6f54-72e9-28e1-de33907d1da6', null, now() - interval '11520 minutes', now() - interval '11500 minutes', now() - interval '11500 minutes', now() - interval '11500 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('faec4cc3-c1d7-62aa-056a-58a6576a43b7', '5364cec5-4b93-658a-9fe9-c5f618689935', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'Are the bowls safe in the microwave?', now() - interval '11518 minutes', now() - interval '11520 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('3539bf74-47b4-66b3-57f2-c87b68f738dc', '5364cec5-4b93-658a-9fe9-c5f618689935', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'Yes, the glaze is food and microwave safe.', now() - interval '11508 minutes', now() - interval '11510 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('b15801c3-ba2f-bf0f-86af-61882f703f6a', '5364cec5-4b93-658a-9fe9-c5f618689935', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'Thanks, ordering now.', now() - interval '11498 minutes', now() - interval '11500 minutes');
  insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)
  values ('43d7ad89-30aa-6ad0-4b1e-6c959f0aea55', '2b7d6168-fb32-2091-6848-977c9ebe9666', '730c2898-4ac5-0424-cecc-e171eae9cd23', 'a9d4ad35-0dc9-c339-a227-3d3a5beec5cb', null, now() - interval '10080 minutes', now() - interval '10070 minutes', now() - interval '10070 minutes', now() - interval '10070 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('9c46372d-b1d6-ebc4-eb1f-eabbd418907b', '43d7ad89-30aa-6ad0-4b1e-6c959f0aea55', '2b7d6168-fb32-2091-6848-977c9ebe9666', 'How long does an inverter install take?', now() - interval '10078 minutes', now() - interval '10080 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('ad3fa804-0286-87a7-88c0-36f844a41b45', '43d7ad89-30aa-6ad0-4b1e-6c959f0aea55', '730c2898-4ac5-0424-cecc-e171eae9cd23', 'About half a day, including testing.', now() - interval '10068 minutes', now() - interval '10070 minutes');
  insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)
  values ('87423a62-27a9-405f-5218-e486818d3333', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', '6d796ecd-d6fb-2673-26d8-241fc8edb639', null, now() - interval '8640 minutes', now() - interval '8630 minutes', now() - interval '8630 minutes', now() - interval '8635 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('90542c5b-805f-676e-0ded-dda2bcc3fd6c', '87423a62-27a9-405f-5218-e486818d3333', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'Can you read in Hausa?', now() - interval '8638 minutes', now() - interval '8640 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('99c17c23-cfd6-41bb-e32b-3587b35574d0', '87423a62-27a9-405f-5218-e486818d3333', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2', 'Not yet, only English, Yoruba and Pidgin. Sorry!', null, now() - interval '8630 minutes');
  insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)
  values ('e48d34f9-a0eb-3afc-02ee-14ba4c03197a', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'b9aecd1f-21a9-2df0-5cb8-a015a841c918', null, now() - interval '7200 minutes', now() - interval '7190 minutes', now() - interval '7190 minutes', now() - interval '7190 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('fb723e2e-88bf-1631-a2bb-a257a5340795', 'e48d34f9-a0eb-3afc-02ee-14ba4c03197a', '078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'Is the price final?', now() - interval '7198 minutes', now() - interval '7200 minutes');
  insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ('003357a5-0cd9-62bf-8fa2-3677d1a2e305', 'e48d34f9-a0eb-3afc-02ee-14ba4c03197a', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'The price is fixed, but delivery is free in Abuja.', now() - interval '7188 minutes', now() - interval '7190 minutes');

  -- 9. Checkouts, orders, payouts, bookings and reviews (test records only; no payment provider involved)
  insert into public.checkouts (id, buyer_id, payment_reference, total_kobo, status, delivery_name, delivery_phone, delivery_address, delivery_city, delivery_state, paid_at, created_at)
  values ('3e71c61d-8671-860d-a453-b178abaa1bd4', '0f89d922-f179-c83a-4035-7269ab41815d', 'SEED-CHECKOUT-0001', 2750000, 'paid', 'Adaeze (seed buyer)', '+2340000000001', '1 Seed Test Street', 'Yaba', 'Lagos', now() - interval '43200 minutes', now() - interval '43205 minutes');
  insert into public.orders (id, checkout_id, buyer_id, seller_id, status, subtotal_kobo, delivery_fee_kobo, platform_fee_kobo, seller_payout_kobo,
    shipped_at, delivered_at, confirm_by, completed_at, created_at)
  values ('8eeaff1e-e94b-5d7f-65e2-2cee58fe7d65', '3e71c61d-8671-860d-a453-b178abaa1bd4', '0f89d922-f179-c83a-4035-7269ab41815d', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'completed'::public.order_status, 2500000, 250000, 250000, 2500000,
    now() - interval '41760 minutes', now() - interval '38880 minutes', null, now() - interval '36000 minutes', now() - interval '43200 minutes');
  insert into public.order_items (order_id, listing_id, title_snapshot, unit_price_kobo, quantity) values ('8eeaff1e-e94b-5d7f-65e2-2cee58fe7d65', 'c9e2cb72-935a-32fa-b317-4b23ab198d39', 'Adire short-sleeve shirt', 2500000, 1);
  insert into public.payouts (order_id, seller_id, amount_kobo, status, transfer_reference, paid_at) values ('8eeaff1e-e94b-5d7f-65e2-2cee58fe7d65', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 2500000, 'paid', 'SEED-PAYOUT-0001', now() - interval '34560 minutes');
  insert into public.reviews (id, order_id, reviewer_id, seller_id, rating, body, seller_reply, seller_replied_at, created_at)
  values ('126e3b70-3dca-de40-d3d8-d75390ced01e', '8eeaff1e-e94b-5d7f-65e2-2cee58fe7d65', '0f89d922-f179-c83a-4035-7269ab41815d', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 5, 'Beautiful shirt, fits well and arrived on time.', null, null, now() - interval '34560 minutes');
  insert into public.checkouts (id, buyer_id, payment_reference, total_kobo, status, delivery_name, delivery_phone, delivery_address, delivery_city, delivery_state, paid_at, created_at)
  values ('ae831aac-86e1-742e-cc4e-3e88e80facbe', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'SEED-CHECKOUT-0002', 3400000, 'paid', 'Ngozi (seed buyer)', '+2340000000002', '2 Seed Test Street', 'Nsukka', 'Enugu', now() - interval '12960 minutes', now() - interval '12965 minutes');
  insert into public.orders (id, checkout_id, buyer_id, seller_id, status, subtotal_kobo, delivery_fee_kobo, platform_fee_kobo, seller_payout_kobo,
    shipped_at, delivered_at, confirm_by, completed_at, created_at)
  values ('5faf9c50-0ffa-7098-bb94-0507380c1764', 'ae831aac-86e1-742e-cc4e-3e88e80facbe', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 'completed'::public.order_status, 3100000, 300000, 310000, 3090000,
    now() - interval '11520 minutes', now() - interval '8640 minutes', null, now() - interval '5760 minutes', now() - interval '12960 minutes');
  insert into public.order_items (order_id, listing_id, title_snapshot, unit_price_kobo, quantity) values ('5faf9c50-0ffa-7098-bb94-0507380c1764', 'e96452f5-6f54-72e9-28e1-de33907d1da6', 'Set of four glazed bowls', 1600000, 1);
  insert into public.order_items (order_id, listing_id, title_snapshot, unit_price_kobo, quantity) values ('5faf9c50-0ffa-7098-bb94-0507380c1764', 'a3bf67c7-fe60-369d-6de2-54bcba3a71a7', 'Hanging planter', 750000, 2);
  insert into public.payouts (order_id, seller_id, amount_kobo, status, transfer_reference, paid_at) values ('5faf9c50-0ffa-7098-bb94-0507380c1764', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 3090000, 'paid', 'SEED-PAYOUT-0002', now() - interval '4320 minutes');
  insert into public.reviews (id, order_id, reviewer_id, seller_id, rating, body, seller_reply, seller_replied_at, created_at)
  values ('d2877aca-64f6-d47d-2045-5fed681919fb', '5faf9c50-0ffa-7098-bb94-0507380c1764', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '1734e54e-6df3-bd1b-3a18-07309e3d2c2f', 4, 'Lovely bowls. One planter had a small chip.', 'Sorry about the chip. We have sent a replacement.', now() - interval '2880 minutes', now() - interval '4320 minutes');
  insert into public.checkouts (id, buyer_id, payment_reference, total_kobo, status, delivery_name, delivery_phone, delivery_address, delivery_city, delivery_state, paid_at, created_at)
  values ('308e17ed-c01c-8927-176a-4ba0c35f226a', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'SEED-CHECKOUT-0003', 1200000, 'paid', 'Tunde (seed buyer)', '+2340000000003', '3 Seed Test Street', 'Ikeja', 'Lagos', now() - interval '5760 minutes', now() - interval '5765 minutes');
  insert into public.orders (id, checkout_id, buyer_id, seller_id, status, subtotal_kobo, delivery_fee_kobo, platform_fee_kobo, seller_payout_kobo,
    shipped_at, delivered_at, confirm_by, completed_at, created_at)
  values ('8b492ef2-b16b-c46f-856a-7ece4628fce5', '308e17ed-c01c-8927-176a-4ba0c35f226a', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', '11fd2b1d-4ff3-f9e7-b81c-e8960f5dc3f8', 'shipped'::public.order_status, 1000000, 200000, 100000, 1100000,
    now() - interval '4320 minutes', null, null, null, now() - interval '5760 minutes');
  insert into public.order_items (order_id, listing_id, title_snapshot, unit_price_kobo, quantity) values ('8b492ef2-b16b-c46f-856a-7ece4628fce5', '92cea08d-873e-be12-7629-8f8b3aad9057', 'Glass bead bracelet', 500000, 2);
  insert into public.checkouts (id, buyer_id, payment_reference, total_kobo, status, delivery_name, delivery_phone, delivery_address, delivery_city, delivery_state, paid_at, created_at)
  values ('7fc9cbd6-f241-c60d-d6f3-7c92afb006ef', '1552c7e1-cc9c-93b7-ba81-3020842f3191', 'SEED-CHECKOUT-0004', 2850000, 'paid', 'Funmi (seed buyer)', '+2340000000004', '4 Seed Test Street', 'Ibadan', 'Oyo', now() - interval '8640 minutes', now() - interval '8645 minutes');
  insert into public.orders (id, checkout_id, buyer_id, seller_id, status, subtotal_kobo, delivery_fee_kobo, platform_fee_kobo, seller_payout_kobo,
    shipped_at, delivered_at, confirm_by, completed_at, created_at)
  values ('cf7edbe5-1210-e895-3b23-048204f23bd3', '7fc9cbd6-f241-c60d-d6f3-7c92afb006ef', '1552c7e1-cc9c-93b7-ba81-3020842f3191', '065cae22-135c-dc6a-d539-8cfc70565d94', 'delivered'::public.order_status, 2700000, 150000, 270000, 2580000,
    now() - interval '7200 minutes', now() - interval '4320 minutes', now() + interval '2880 minutes', null, now() - interval '8640 minutes');
  insert into public.order_items (order_id, listing_id, title_snapshot, unit_price_kobo, quantity) values ('cf7edbe5-1210-e895-3b23-048204f23bd3', '5bc541dd-6d66-1b2e-f2be-1fb6e7ba6c2c', 'Kampala fabric by the yard', 450000, 6);
  insert into public.bookings (id, buyer_id, pro_id, listing_id, request_offer_id, job_details, service_address, city, state, preferred_date, preferred_window, scheduled_at, status, created_at, updated_at)
  values ('a7267121-87a2-db50-b024-ff02deb91b02', '2b7d6168-fb32-2091-6848-977c9ebe9666', '730c2898-4ac5-0424-cecc-e171eae9cd23', 'a9d4ad35-0dc9-c339-a227-3d3a5beec5cb', null, 'Install a 3.5 kVA inverter with two batteries.', 'Flat 2, Seed Test Close', 'Surulere', 'Lagos', (now() - interval '16 days')::date, 'afternoon', now() - interval '16 days', 'completed'::public.booking_status, now() - interval '24480 minutes', now() - interval '24480 minutes');
  insert into public.reviews (id, booking_id, reviewer_id, seller_id, rating, body, created_at) values ('b9a66b7e-c385-02fb-3e32-c5d82e4e9485', 'a7267121-87a2-db50-b024-ff02deb91b02', '2b7d6168-fb32-2091-6848-977c9ebe9666', '730c2898-4ac5-0424-cecc-e171eae9cd23', 5, 'Neat work and explained everything.', now() - interval '21600 minutes');
  insert into public.bookings (id, buyer_id, pro_id, listing_id, request_offer_id, job_details, service_address, city, state, preferred_date, preferred_window, scheduled_at, status, created_at, updated_at)
  values ('29a9b6de-a3d4-daf0-2daa-d1da95150e9c', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', '66f3d05d-39c9-abbc-dab0-8e81f36d5c74', null, '6f9853bb-4d93-5315-8a35-d8e7bffaac00', 'Service two split units, check gas.', 'Flat 2, Seed Test Close', 'Enugu', 'Enugu', (now() - interval '-3 days')::date, 'afternoon', now() - interval '-3 days', 'scheduled'::public.booking_status, now() - interval '5760 minutes', now() - interval '5760 minutes');
  insert into public.bookings (id, buyer_id, pro_id, listing_id, request_offer_id, job_details, service_address, city, state, preferred_date, preferred_window, scheduled_at, status, created_at, updated_at)
  values ('7e4299be-1211-4721-bf77-d7b5135a6527', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'b7290ec9-1c5a-32bd-9560-9d8463eee431', '075f9a3f-cd53-fb89-2ffb-a4244f986e29', null, 'Deep clean before moving in.', 'Flat 2, Seed Test Close', 'Nsukka', 'Enugu', (now() - interval '-10 days')::date, 'afternoon', null, 'requested'::public.booking_status, now() - interval '15840 minutes', now() - interval '15840 minutes');

  -- 10. Saves, follows, carts, blocks, reports, referrals, share links, notifications, searches, listing views
  insert into public.saves (user_id, listing_id) values ('0f89d922-f179-c83a-4035-7269ab41815d', '8fe890b4-d7c8-47d0-dde4-49a1877c5a94');
  insert into public.saves (user_id, listing_id) values ('0f89d922-f179-c83a-4035-7269ab41815d', 'e4793072-8918-befb-d0ff-14523ba65b3c');
  insert into public.saves (user_id, listing_id) values ('0f89d922-f179-c83a-4035-7269ab41815d', '7a9d37ca-38a9-9806-aa44-779a00b9fcc7');
  insert into public.saves (user_id, listing_id) values ('0f89d922-f179-c83a-4035-7269ab41815d', 'a9d4ad35-0dc9-c339-a227-3d3a5beec5cb');
  insert into public.follows (follower_id, seller_id) values ('0f89d922-f179-c83a-4035-7269ab41815d', '730c2898-4ac5-0424-cecc-e171eae9cd23');
  insert into public.follows (follower_id, seller_id) values ('0f89d922-f179-c83a-4035-7269ab41815d', '065cae22-135c-dc6a-d539-8cfc70565d94');
  insert into public.follows (follower_id, seller_id) values ('0f89d922-f179-c83a-4035-7269ab41815d', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729');
  insert into public.saves (user_id, listing_id) values ('c6f897e2-0390-b115-2cf3-2871fcac34ba', '8fe890b4-d7c8-47d0-dde4-49a1877c5a94');
  insert into public.saves (user_id, listing_id) values ('c6f897e2-0390-b115-2cf3-2871fcac34ba', '91f924b7-2755-b6f0-3d3b-993b661ce8be');
  insert into public.saves (user_id, listing_id) values ('c6f897e2-0390-b115-2cf3-2871fcac34ba', 'a53fe992-aa64-4486-852d-b2bc27361c12');
  insert into public.saves (user_id, listing_id) values ('c6f897e2-0390-b115-2cf3-2871fcac34ba', '97b9d80a-bb7a-f47f-2c28-3a402c726dc4');
  insert into public.follows (follower_id, seller_id) values ('c6f897e2-0390-b115-2cf3-2871fcac34ba', '065cae22-135c-dc6a-d539-8cfc70565d94');
  insert into public.follows (follower_id, seller_id) values ('c6f897e2-0390-b115-2cf3-2871fcac34ba', 'fabae036-2d8c-f09e-cbd7-101d945f64a0');
  insert into public.follows (follower_id, seller_id) values ('c6f897e2-0390-b115-2cf3-2871fcac34ba', '5b685f38-9471-8789-5ba8-9609f1ee3484');
  insert into public.saves (user_id, listing_id) values ('fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', '9fceb0d5-c756-7c82-cdae-c569a1ce3e88');
  insert into public.saves (user_id, listing_id) values ('fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', '3c06cb94-7d97-8145-a1d2-ff3eafeced3a');
  insert into public.saves (user_id, listing_id) values ('fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'b3e3d48b-e6bf-c1a9-4d2a-061fbc737cfe');
  insert into public.saves (user_id, listing_id) values ('fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'e96452f5-6f54-72e9-28e1-de33907d1da6');
  insert into public.follows (follower_id, seller_id) values ('fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', '5b685f38-9471-8789-5ba8-9609f1ee3484');
  insert into public.follows (follower_id, seller_id) values ('fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'b7290ec9-1c5a-32bd-9560-9d8463eee431');
  insert into public.follows (follower_id, seller_id) values ('fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'c3a4ff94-6cad-eb2e-4bbc-6099a2dd2c34');
  insert into public.saves (user_id, listing_id) values ('0b247d05-4c2d-3855-10ca-1ac40c298aca', '5dd229ee-4840-ce1f-fb95-c9e949052242');
  insert into public.saves (user_id, listing_id) values ('0b247d05-4c2d-3855-10ca-1ac40c298aca', '34caa851-e5d7-e63a-f896-430ba2773cc2');
  insert into public.saves (user_id, listing_id) values ('0b247d05-4c2d-3855-10ca-1ac40c298aca', '6d796ecd-d6fb-2673-26d8-241fc8edb639');
  insert into public.saves (user_id, listing_id) values ('0b247d05-4c2d-3855-10ca-1ac40c298aca', '090a9bd4-17d3-fa68-1adc-103a5c945a46');
  insert into public.follows (follower_id, seller_id) values ('0b247d05-4c2d-3855-10ca-1ac40c298aca', '19d2c070-1501-1c48-da57-d74352bbde02');
  insert into public.follows (follower_id, seller_id) values ('0b247d05-4c2d-3855-10ca-1ac40c298aca', '730c2898-4ac5-0424-cecc-e171eae9cd23');
  insert into public.follows (follower_id, seller_id) values ('0b247d05-4c2d-3855-10ca-1ac40c298aca', '8f7b4275-b407-2f4a-21f6-778871f6cb28');
  insert into public.saves (user_id, listing_id) values ('1552c7e1-cc9c-93b7-ba81-3020842f3191', 'b3e3d48b-e6bf-c1a9-4d2a-061fbc737cfe');
  insert into public.saves (user_id, listing_id) values ('1552c7e1-cc9c-93b7-ba81-3020842f3191', '5dd229ee-4840-ce1f-fb95-c9e949052242');
  insert into public.saves (user_id, listing_id) values ('1552c7e1-cc9c-93b7-ba81-3020842f3191', 'b9aecd1f-21a9-2df0-5cb8-a015a841c918');
  insert into public.saves (user_id, listing_id) values ('1552c7e1-cc9c-93b7-ba81-3020842f3191', '65003b04-4337-0ee0-54a7-8af5dc80cbdf');
  insert into public.follows (follower_id, seller_id) values ('1552c7e1-cc9c-93b7-ba81-3020842f3191', '5b685f38-9471-8789-5ba8-9609f1ee3484');
  insert into public.follows (follower_id, seller_id) values ('1552c7e1-cc9c-93b7-ba81-3020842f3191', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2');
  insert into public.follows (follower_id, seller_id) values ('1552c7e1-cc9c-93b7-ba81-3020842f3191', '065cae22-135c-dc6a-d539-8cfc70565d94');
  insert into public.saves (user_id, listing_id) values ('078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'a9d4ad35-0dc9-c339-a227-3d3a5beec5cb');
  insert into public.saves (user_id, listing_id) values ('078cf7cd-d43e-8909-4e82-3a8f54700ba4', '91f924b7-2755-b6f0-3d3b-993b661ce8be');
  insert into public.saves (user_id, listing_id) values ('078cf7cd-d43e-8909-4e82-3a8f54700ba4', '9fceb0d5-c756-7c82-cdae-c569a1ce3e88');
  insert into public.saves (user_id, listing_id) values ('078cf7cd-d43e-8909-4e82-3a8f54700ba4', '075f9a3f-cd53-fb89-2ffb-a4244f986e29');
  insert into public.follows (follower_id, seller_id) values ('078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0');
  insert into public.follows (follower_id, seller_id) values ('078cf7cd-d43e-8909-4e82-3a8f54700ba4', 'b7290ec9-1c5a-32bd-9560-9d8463eee431');
  insert into public.follows (follower_id, seller_id) values ('078cf7cd-d43e-8909-4e82-3a8f54700ba4', '8f7b4275-b407-2f4a-21f6-778871f6cb28');
  insert into public.saves (user_id, listing_id) values ('f6d2c74a-a808-09cc-0aca-251d36d2d751', '090a9bd4-17d3-fa68-1adc-103a5c945a46');
  insert into public.saves (user_id, listing_id) values ('f6d2c74a-a808-09cc-0aca-251d36d2d751', '97b9d80a-bb7a-f47f-2c28-3a402c726dc4');
  insert into public.saves (user_id, listing_id) values ('f6d2c74a-a808-09cc-0aca-251d36d2d751', '7a9d37ca-38a9-9806-aa44-779a00b9fcc7');
  insert into public.saves (user_id, listing_id) values ('f6d2c74a-a808-09cc-0aca-251d36d2d751', '65003b04-4337-0ee0-54a7-8af5dc80cbdf');
  insert into public.follows (follower_id, seller_id) values ('f6d2c74a-a808-09cc-0aca-251d36d2d751', '8f7b4275-b407-2f4a-21f6-778871f6cb28');
  insert into public.follows (follower_id, seller_id) values ('f6d2c74a-a808-09cc-0aca-251d36d2d751', 'f7ceeee9-03bd-e75d-b2a4-419d72ba62b2');
  insert into public.follows (follower_id, seller_id) values ('f6d2c74a-a808-09cc-0aca-251d36d2d751', '88c5246a-1dab-e4f8-713a-e010c752dfb2');
  insert into public.saves (user_id, listing_id) values ('2b7d6168-fb32-2091-6848-977c9ebe9666', 'c9e2cb72-935a-32fa-b317-4b23ab198d39');
  insert into public.saves (user_id, listing_id) values ('2b7d6168-fb32-2091-6848-977c9ebe9666', '65003b04-4337-0ee0-54a7-8af5dc80cbdf');
  insert into public.saves (user_id, listing_id) values ('2b7d6168-fb32-2091-6848-977c9ebe9666', 'e96452f5-6f54-72e9-28e1-de33907d1da6');
  insert into public.saves (user_id, listing_id) values ('2b7d6168-fb32-2091-6848-977c9ebe9666', '09251ec4-ea6f-71f0-0105-e0ade86d2a5c');
  insert into public.follows (follower_id, seller_id) values ('2b7d6168-fb32-2091-6848-977c9ebe9666', '730c2898-4ac5-0424-cecc-e171eae9cd23');
  insert into public.follows (follower_id, seller_id) values ('2b7d6168-fb32-2091-6848-977c9ebe9666', '19d2c070-1501-1c48-da57-d74352bbde02');
  insert into public.follows (follower_id, seller_id) values ('2b7d6168-fb32-2091-6848-977c9ebe9666', '8f7b4275-b407-2f4a-21f6-778871f6cb28');
  insert into public.saves (user_id, listing_id) values ('2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '856df9c3-701c-763d-1645-6be8d8a504c0');
  insert into public.saves (user_id, listing_id) values ('2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '090a9bd4-17d3-fa68-1adc-103a5c945a46');
  insert into public.saves (user_id, listing_id) values ('2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '6d796ecd-d6fb-2673-26d8-241fc8edb639');
  insert into public.saves (user_id, listing_id) values ('2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '5dd229ee-4840-ce1f-fb95-c9e949052242');
  insert into public.follows (follower_id, seller_id) values ('2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729');
  insert into public.follows (follower_id, seller_id) values ('2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '19d2c070-1501-1c48-da57-d74352bbde02');
  insert into public.follows (follower_id, seller_id) values ('2e79d2f5-2d03-9d9f-7ee6-18434adc0747', '388fc4c1-d047-6efc-6d86-abdc0435b188');
  insert into public.cart_items (user_id, listing_id, quantity) values ('0f89d922-f179-c83a-4035-7269ab41815d', '65003b04-4337-0ee0-54a7-8af5dc80cbdf', 1);
  insert into public.cart_items (user_id, listing_id, quantity) values ('f6d2c74a-a808-09cc-0aca-251d36d2d751', '92cea08d-873e-be12-7629-8f8b3aad9057', 3);
  insert into public.cart_items (user_id, listing_id, quantity) values ('0b247d05-4c2d-3855-10ca-1ac40c298aca', 'a3bf67c7-fe60-369d-6de2-54bcba3a71a7', 2);
  insert into public.user_blocks (blocker_id, blocked_id) values ('2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'd0046b6c-9ee4-ce71-acbc-6f863000a675');
  insert into public.reports (id, reporter_id, listing_id, reason, details) values ('02b44300-ef13-5b46-fd6a-3c339e5894c6', 'f6d2c74a-a808-09cc-0aca-251d36d2d751', 'a53fe992-aa64-4486-852d-b2bc27361c12', 'misleading', 'Seed report: the size in the photos looks different.');
  insert into public.reports (id, reporter_id, request_id, reason, details) values ('c313267d-0283-8e2d-2c5c-4541cba3ccd9', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', '0582abed-d729-a640-5f32-83261d87f537', 'other', 'Seed report on a request.');
  insert into public.reports (id, reporter_id, reported_user_id, reason, details, status, handled_by, handled_at, resolution_note) values ('9ddbeb1f-f362-2cc2-b3a5-238e6de35eaa', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'd0046b6c-9ee4-ce71-acbc-6f863000a675', 'harassment', 'Seed report: rude messages.', 'actioned', '97d27a6b-386a-886c-c532-3848a47852c8', now() - interval '9 days', 'Seed: account banned.');
  insert into public.referrals (referrer_id, referred_id, reward_status) values ('0f89d922-f179-c83a-4035-7269ab41815d', 'fbf11cc3-b145-24c9-2529-16d3ab6a5fc2', 'pending');
  insert into public.share_links (id, code, listing_id, created_by, clicks) values ('ca405b5b-3c58-8917-709b-8fd92450b832', 'seedshare1', '5dd229ee-4840-ce1f-fb95-c9e949052242', '0f89d922-f179-c83a-4035-7269ab41815d', 7);
  insert into public.notifications (id, recipient_id, type, title, body, created_at) values ('450083a5-e4c8-18ab-653f-e3d592ee2080', '43be0c1d-e9b1-6e0b-784d-30ccc14e8729', 'new_message'::public.notification_type, 'New message', 'Adaeze asked about the adire shirt.', now() - interval '300 minutes');
  insert into public.notifications (id, recipient_id, type, title, body, created_at) values ('da92c5b9-6d8d-ca35-934b-dd83c0bcd74e', 'c6f897e2-0390-b115-2cf3-2871fcac34ba', 'request_offer'::public.notification_type, 'New offer on your request', 'DevCraft Studio sent an offer.', now() - interval '600 minutes');
  insert into public.notifications (id, recipient_id, type, title, body, created_at) values ('215e4877-dfee-a9c4-0130-ee761894e3fa', '2e79d2f5-2d03-9d9f-7ee6-18434adc0747', 'order_update'::public.notification_type, 'Order delivered', 'Your order from Clay and Kiln was delivered.', now() - interval '900 minutes');
  insert into public.notifications (id, recipient_id, type, title, body, created_at) values ('91b38ded-e85f-948f-3d76-3726720f096e', 'e130dba3-7e8d-5d3b-7b0b-f382d5b383d0', 'listing_review'::public.notification_type, 'Listing in review', 'Website speed check is waiting for review.', now() - interval '1200 minutes');
  insert into public.notifications (id, recipient_id, type, title, body, created_at) values ('e962115f-4609-0d5c-ec75-7c121884380d', 'fabae036-2d8c-f09e-cbd7-101d945f64a0', 'verification_update'::public.notification_type, 'ID check not approved', 'Please upload a clearer photo of your document.', now() - interval '1500 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('adire', 1, 3, now() - interval '30 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('ankara', 1, 0, now() - interval '430 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('website', 5, 2, now() - interval '830 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('logo', 3, 2, now() - interval '1230 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('ac repair', 6, 2, now() - interval '1630 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('photographer', 4, 2, now() - interval '2030 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('vase', 2, 1, now() - interval '2430 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('electrician', 6, 1, now() - interval '2830 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('bead necklace', 2, 1, now() - interval '3230 minutes');
  insert into public.search_queries (query, category_id, results_count, created_at) values ('voice over', 4, 2, now() - interval '3630 minutes');
  insert into public.listing_events (listing_id, event_type, created_at) select '5dd229ee-4840-ce1f-fb95-c9e949052242', 'view', now() - (g || ' hours')::interval from generate_series(1, 10) g;
  insert into public.listing_events (listing_id, event_type, created_at) select 'c9e2cb72-935a-32fa-b317-4b23ab198d39', 'view', now() - (g || ' hours')::interval from generate_series(1, 3) g;
  insert into public.listing_events (listing_id, event_type, created_at) select '5bc541dd-6d66-1b2e-f2be-1fb6e7ba6c2c', 'view', now() - (g || ' hours')::interval from generate_series(1, 16) g;
  insert into public.listing_events (listing_id, event_type, created_at) select '65003b04-4337-0ee0-54a7-8af5dc80cbdf', 'view', now() - (g || ' hours')::interval from generate_series(1, 10) g;
  insert into public.listing_events (listing_id, event_type, created_at) select '34caa851-e5d7-e63a-f896-430ba2773cc2', 'view', now() - (g || ' hours')::interval from generate_series(1, 4) g;
  insert into public.listing_events (listing_id, event_type, created_at) select 'e96452f5-6f54-72e9-28e1-de33907d1da6', 'view', now() - (g || ' hours')::interval from generate_series(1, 18) g;

  -- 11. Account states for test cases (last, so earlier inserts are not blocked)
  update public.profiles set account_status = 'banned', status_reason = 'Seed: banned test account' where id = 'd0046b6c-9ee4-ce71-acbc-6f863000a675';
  update public.profiles set account_status = 'suspended', status_reason = 'Seed: suspended test account', suspended_until = now() + interval '7 days' where id = '3850c6d8-9934-1f10-5264-6740dff2d7d6';
  update public.profiles set account_status = 'suspended', status_reason = 'Seed: suspended test shop', suspended_until = now() + interval '14 days' where id = 'd2f025fb-3d20-e8ca-aea7-9aef6901479b';
  update public.profiles set deletion_requested_at = now() - interval '2 days' where id = '0c2aad9d-7eae-3d0e-a0ea-ca9cd49d9cd1';


  -- ---------------------------------------------------------------- completion marker (last step)
  perform vault.create_secret(
    jsonb_build_object('status', 'complete', 'generator', 'w6-2', 'digest', 'b10f52cb983e10727e8726c6d62cf9dcb19012afa985c8409a39a960a8cea4ee',
                       'accounts', 32, 'target', v_target, 'completed_at', now())::text,
    'purple_seed_marker', 'W6 synthetic seed: completion marker (written only when the whole seed succeeded)');
end $seed$;
