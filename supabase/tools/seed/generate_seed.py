#!/usr/bin/env python3
"""Generate supabase/seed.sql: synthetic Purple Shop data for staging and local databases.

Usage:
    python3 supabase/tools/seed/generate_seed.py            # (re)write supabase/seed.sql
    python3 supabase/tools/seed/generate_seed.py --check    # exit 1 if supabase/seed.sql is out of date

Everything here is invented. No production data is read or copied.
- IDs are fixed UUIDs derived from a key (md5("purple-seed/<key>")), so every run produces the same file.
- Email addresses use the reserved .test domain (seed.purple.test): they can never receive mail.
- Display names and shop names carry "(seed)" so synthetic accounts are recognisable on screen.
- Passwords are not in the file. seed.sql reads `purple.seed_password` if it is set for the session;
  otherwise every account gets a random, unknown password (nobody can sign in).
- Media paths point at files that do not exist yet (see docs/W6-SEED-AND-ANONYMIZER.md).

The SQL refuses to run on a database that has any non-seed user (so never on production),
and refuses to run twice.
"""
import hashlib
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "supabase" / "seed.sql"
DOMAIN = "seed.purple.test"
PROD_REF = "nozxxxldfthbwhjwbsmy"
RNG = random.Random(20261119)

CAT = {"fashion-adire": 1, "art-crafts": 2, "digital-design": 3, "photo-video-talent": 4,
       "tech-freelance": 5, "home-services": 6}


def uid(key):
    h = hashlib.md5(("purple-seed/" + key).encode()).hexdigest()
    return f"{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}"


def q(v):
    """SQL literal."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, (list, tuple)):
        return "array[" + ", ".join(q(x) for x in v) + "]::text[]" if v else "'{}'::text[]"
    return "'" + str(v).replace("'", "''") + "'"


def ago(minutes):
    """Timestamp `minutes` before the moment the seed runs."""
    return f"now() - interval '{int(minutes)} minutes'"


def ahead(minutes):
    return f"now() + interval '{int(minutes)} minutes'"


DAY = 24 * 60

# ---------------------------------------------------------------------------
# People
# ---------------------------------------------------------------------------
# key, display name, username, state, city, joined (days ago)
BUYERS = [
    ("adaeze", "Adaeze (seed buyer)", "Lagos", "Yaba", 58),
    ("tunde", "Tunde (seed buyer)", "Lagos", "Ikeja", 55),
    ("chiamaka", "Chiamaka (seed buyer)", "Enugu", "Enugu", 50),
    ("ibrahim", "Ibrahim (seed buyer)", "Kano", "Kano", 46),
    ("funmi", "Funmi (seed buyer)", "Oyo", "Ibadan", 40),
    ("emeka", "Emeka (seed buyer)", "Rivers", "Port Harcourt", 33),
    ("zainab", "Zainab (seed buyer)", "FCT", "Abuja", 27),
    ("segun", "Segun (seed buyer)", "Lagos", "Surulere", 21),
    ("ngozi", "Ngozi (seed buyer)", "Enugu", "Nsukka", 14),
    ("musa", "Musa (seed buyer, banned)", "Kaduna", "Kaduna", 10),
    ("bisi", "Bisi (seed buyer, suspended)", "Ogun", "Abeokuta", 6),
    ("kelechi", "Kelechi (seed buyer, leaving)", "Lagos", "Lekki", 3),
]

# Sellers. persona: product | freelancer | home | creative
# key, shop name, persona, category slug, state, city, joined days, verification, pro_mode, pro_public, headline, bio, skills, languages, years
SELLERS = [
    ("adire_house", "Adire House (seed)", "product", "fashion-adire", "Lagos", "Yaba", 57, "approved", None, False,
     "Hand-dyed adire from Abeokuta indigo", "Small studio making indigo adire fabric and ready-to-wear pieces. Every piece is dyed by hand.",
     [], ["English", "Yoruba"], 9),
    ("kampala_corner", "Kampala Corner (seed)", "product", "fashion-adire", "Oyo", "Ibadan", 52, "approved", None, False,
     "Tie-dye kampala in bright colours", "Family workshop selling kampala fabric by the yard and simple dresses.",
     [], ["English", "Yoruba"], 15),
    ("ankara_atelier", "Ankara Atelier (seed)", "product", "fashion-adire", "Lagos", "Lekki", 12, "pending", None, False,
     "Ankara two-pieces made to order", "New tailoring studio. ID check in progress.",
     [], ["English"], 2),
    ("clay_and_kiln", "Clay and Kiln (seed)", "product", "art-crafts", "Enugu", "Enugu", 48, "approved", None, False,
     "Wheel-thrown pottery and vases", "Potter working with local clay. Vases, bowls and planters fired in a wood kiln.",
     [], ["English", "Igbo"], 11),
    ("bead_works", "Bead Works (seed)", "product", "art-crafts", "FCT", "Abuja", 44, "approved", None, False,
     "Coral and glass bead jewellery", "Bead necklaces, bracelets and bridal sets, strung by hand.",
     [], ["English", "Hausa"], 7),
    ("canvas_corner", "Canvas Corner (seed, suspended)", "product", "art-crafts", "Ogun", "Abeokuta", 39, "approved", None, False,
     "Acrylic paintings of city life", "Painter selling originals and prints. Account suspended for a test case.",
     [], ["English"], 5),
    ("devcraft", "DevCraft Studio (seed)", "freelancer", "tech-freelance", "Lagos", "Ikeja", 47, "approved", "professional", True,
     "Web apps for small businesses", "Two developers building websites, online stores and booking systems for small firms.",
     ["Next.js", "TypeScript", "PostgreSQL", "UI design"], ["English"], 8),
    ("tobi_dev", "Tobi (seed freelancer)", "freelancer", "tech-freelance", "Oyo", "Ibadan", 36, "approved", "professional", True,
     "Mobile developer, Flutter and Kotlin", "Freelance mobile developer. I build and maintain Android and iOS apps.",
     ["Flutter", "Kotlin", "Firebase"], ["English", "Yoruba"], 5),
    ("data_amaka", "Amaka Data (seed)", "freelancer", "tech-freelance", "Enugu", "Enugu", 30, "approved", "professional", False,
     "Spreadsheets, dashboards and data cleaning", "Data analyst helping shops make sense of sales records.",
     ["Excel", "SQL", "Power BI"], ["English", "Igbo"], 4),
    ("pixel_forge", "Pixel Forge (seed)", "freelancer", "digital-design", "Lagos", "Yaba", 42, "approved", "creative_space", True,
     "Brand identity and packaging design", "Design studio for logos, packaging and social media templates.",
     ["Branding", "Illustration", "Packaging"], ["English"], 6),
    ("logo_lab", "Logo Lab (seed)", "freelancer", "digital-design", "Kano", "Kano", 18, None, "professional", False,
     "Fast logo design", "Logo designer. Page not public yet.",
     ["Logo design"], ["English", "Hausa"], 3),
    ("spark_electric", "Spark Electric (seed)", "home", "home-services", "Lagos", "Surulere", 45, "approved", None, False,
     "Licensed electrician, wiring and repairs", "House wiring, fault finding, inverter installs and socket repairs.",
     [], ["English", "Yoruba"], 12),
    ("cool_air_fix", "Cool Air Fix (seed)", "home", "home-services", "FCT", "Abuja", 41, "approved", None, False,
     "AC installation and servicing", "Air conditioner servicing, gas refills and installation.",
     [], ["English", "Hausa"], 10),
    ("clean_sweep", "Clean Sweep (seed)", "home", "home-services", "Rivers", "Port Harcourt", 35, "approved", None, False,
     "Home and office deep cleaning", "Cleaning crew for homes, offices and post-renovation jobs.",
     [], ["English"], 6),
    ("fix_it_femi", "Fix It Femi (seed)", "home", "home-services", "Kaduna", "Kaduna", 8, "pending", None, False,
     "Plumbing and small repairs", "Plumber. Waiting for ID check, so listings are drafts.",
     [], ["English", "Hausa"], 4),
    ("lens_and_light", "Lens and Light (seed)", "creative", "photo-video-talent", "Lagos", "Lekki", 49, "approved", "creative_space", True,
     "Event and portrait photography", "Photographer covering weddings, naming ceremonies and studio portraits.",
     ["Photography", "Lightroom", "Portraits"], ["English", "Yoruba"], 9),
    ("voice_by_ife", "Voice by Ife (seed)", "creative", "photo-video-talent", "Oyo", "Ibadan", 31, "approved", "creative_space", True,
     "Voice-over for adverts and audiobooks", "Voice artist with a home studio. English, Yoruba and Pidgin reads.",
     ["Voice-over", "Audio editing"], ["English", "Yoruba", "Pidgin"], 6),
    ("drum_circle", "Drum Circle Band (seed)", "creative", "photo-video-talent", "Lagos", "Ikeja", 26, "approved", "creative_space", True,
     "Live highlife and talking drum band", "Six-piece band for weddings and parties.",
     ["Highlife", "Talking drum"], ["English", "Yoruba"], 11),
    ("mc_kunle", "MC Kunle (seed)", "creative", "photo-video-talent", "Lagos", "Surulere", 16, "rejected", "professional", False,
     "Event host and MC", "Bilingual MC for parties and corporate events.",
     ["Event hosting"], ["English", "Yoruba"], 7),
]

# ---------------------------------------------------------------------------
# Listings: seller, key, type, title, description, naira, starting, stock, delivery, status, extra
# ---------------------------------------------------------------------------
LISTINGS = [
    ("adire_house", "adire_wrapper", "product", "Indigo adire wrapper, two yards", "Hand-dyed indigo adire, two yards, cotton. Soft after the first wash.", 18000, False, 12, "delivery", "approved"),
    ("adire_house", "adire_shirt", "product", "Adire short-sleeve shirt", "Unisex adire shirt in sizes S to XXL. Made to order in five working days.", 25000, False, 8, "delivery", "approved"),
    ("adire_house", "adire_bag", "product", "Adire tote bag", "Lined tote bag with inner pocket.", 9500, False, 0, "delivery", "rejected"),
    ("kampala_corner", "kampala_yard", "product", "Kampala fabric by the yard", "Bright tie-dye kampala, sold per yard. Choose colours at checkout.", 4500, True, 40, "pickup", "approved"),
    ("kampala_corner", "kampala_dress", "product", "Kampala midi dress", "Simple midi dress with pockets.", 22000, False, 5, "delivery", "approved"),
    ("ankara_atelier", "ankara_two_piece", "product", "Ankara two-piece set", "Top and trousers, made to measure.", 35000, True, 3, "delivery", "pending"),
    ("ankara_atelier", "ankara_cap", "product", "Ankara bucket hat", "Reversible bucket hat.", 6000, False, 10, "delivery", "draft"),
    ("clay_and_kiln", "clay_vase", "product", "Tall terracotta vase", "Wheel-thrown vase, about 40 cm tall, unglazed outside.", 28000, False, 6, "pickup", "approved"),
    ("clay_and_kiln", "clay_bowls", "product", "Set of four glazed bowls", "Stoneware bowls in a green glaze. Food safe.", 16000, False, 10, "delivery", "approved"),
    ("clay_and_kiln", "clay_planter", "product", "Hanging planter", "Small planter with cord hanger.", 7500, False, 15, "delivery", "approved"),
    ("bead_works", "bead_necklace", "product", "Coral bead necklace", "Three-strand coral bead necklace with brass clasp.", 32000, False, 4, "delivery", "approved"),
    ("bead_works", "bead_bracelet", "product", "Glass bead bracelet", "Stretch bracelet in mixed glass beads.", 5000, False, 30, "delivery", "approved"),
    ("bead_works", "bead_bridal", "product", "Bridal bead set", "Necklace, earrings and bracelet for traditional weddings.", 85000, True, 2, "delivery", "removed"),
    ("canvas_corner", "canvas_lagos", "product", "Lagos traffic, acrylic on canvas", "Original painting, 60 by 90 cm.", 120000, False, 1, "pickup", "approved"),
    ("devcraft", "dev_website", "service", "Small business website", "Five-page website with contact form and hosting set up. Delivered in two weeks.", 250000, True, None, "remote_service", "approved"),
    ("devcraft", "dev_store", "service", "Online store setup", "Product catalogue, cart and order emails for up to 100 products.", 450000, True, None, "remote_service", "approved"),
    ("devcraft", "dev_audit", "service", "Website speed check", "Report on what slows a site down and how to fix it.", 60000, False, None, "remote_service", "pending"),
    ("tobi_dev", "tobi_app", "service", "Android app from your design", "Build an Android app from Figma screens. Price depends on the number of screens.", 400000, True, None, "remote_service", "approved"),
    ("tobi_dev", "tobi_fix", "service", "App bug fixing, per day", "One day of debugging and fixes on an existing Flutter app.", 45000, False, None, "remote_service", "approved"),
    ("data_amaka", "amaka_dashboard", "service", "Sales dashboard in Excel", "Monthly sales dashboard built from your records.", 75000, True, None, "remote_service", "approved"),
    ("pixel_forge", "pixel_logo", "service", "Logo and brand colours", "Three logo concepts, two rounds of changes, colour palette.", 90000, True, None, "remote_service", "approved"),
    ("pixel_forge", "pixel_templates", "product", "Social media template pack", "Thirty editable post templates. Delivered as a download.", 15000, False, 999, "digital", "approved"),
    ("logo_lab", "logo_quick", "service", "Logo in 48 hours", "One concept, one revision.", 25000, False, None, "remote_service", "draft"),
    ("spark_electric", "spark_wiring", "service", "House rewiring", "Full or partial rewiring. Site visit first, then a written quote.", 0, False, None, "in_person_service", "approved", {"quote": True}),
    ("spark_electric", "spark_inverter", "service", "Inverter installation", "Install and test an inverter and battery bank.", 35000, True, None, "in_person_service", "approved"),
    ("cool_air_fix", "cool_service", "service", "Split AC servicing", "Clean filters and coils, check gas, per unit.", 12000, False, None, "in_person_service", "approved"),
    ("cool_air_fix", "cool_install", "service", "AC installation", "Install a new split unit, including bracket.", 40000, True, None, "in_person_service", "approved"),
    ("clean_sweep", "clean_deep", "service", "Deep cleaning, three-bedroom flat", "Two cleaners, about six hours, materials included.", 55000, False, None, "in_person_service", "approved"),
    ("clean_sweep", "clean_office", "service", "Office cleaning, weekly", "Weekly cleaning for small offices.", 0, False, None, "in_person_service", "approved", {"quote": True}),
    ("fix_it_femi", "femi_plumbing", "service", "Leaking tap and pipe repairs", "Fix leaks, replace taps and valves.", 8000, True, None, "in_person_service", "draft"),
    ("lens_and_light", "lens_event", "talent", "Event photography, half day", "Up to four hours of coverage and 150 edited photos.", 120000, True, None, "in_person_service", "approved"),
    ("lens_and_light", "lens_portrait", "talent", "Studio portrait session", "One hour in studio, ten edited portraits.", 40000, False, None, "in_person_service", "approved"),
    ("voice_by_ife", "ife_advert", "talent", "Radio advert voice-over", "Thirty-second advert read, two takes, broadcast quality.", 30000, False, None, "remote_service", "approved"),
    ("voice_by_ife", "ife_audiobook", "talent", "Audiobook narration, per finished hour", "Narration and basic editing.", 70000, True, None, "remote_service", "approved"),
    ("drum_circle", "drum_wedding", "talent", "Live band for weddings", "Three hours of highlife and talking drum.", 300000, True, None, "in_person_service", "approved"),
    ("mc_kunle", "kunle_mc", "talent", "MC for parties", "Bilingual MC, up to five hours.", 80000, True, None, "in_person_service", "approved"),
]

REJECTION = {"adire_bag": "Seed: photos do not show the product clearly."}


def build():
    out = []
    w = out.append

    w("-- =====================================================================")
    w("-- Purple Shop synthetic seed. GENERATED FILE: do not edit by hand.")
    w("-- Source: supabase/tools/seed/generate_seed.py (run it to regenerate).")
    w("-- Every name, message and figure below is invented. Staging and local only.")
    w("-- Docs: docs/W6-SEED-AND-ANONYMIZER.md")
    w("-- =====================================================================")
    w("")
    w("-- Guards: never production, never twice.")
    w("do $guard$")
    w("begin")
    w(f"  if exists (select 1 from vault.decrypted_secrets where name = 'project_url' and decrypted_secret like '%{PROD_REF}%') then")
    w("    raise exception 'seed.sql refused: this is the production project';")
    w("  end if;")
    w(f"  if exists (select 1 from auth.users where email is null or email not like '%@{DOMAIN}') then")
    w("    raise exception 'seed.sql refused: this database has real (non-seed) users';")
    w("  end if;")
    w(f"  if exists (select 1 from auth.users where id = {q(uid('user/admin'))}) then")
    w("    raise exception 'seed.sql: this database is already seeded';")
    w("  end if;")
    w("end $guard$;")
    w("")

    people = []  # (key, email_local, display, username, state, city, joined_days)
    people.append(("admin", "admin", "Seed Admin", "seed_admin", "Lagos", "Ikeja", 60))
    for k, name, st, city, d in BUYERS:
        people.append((k, f"buyer.{k}", name, f"seed_{k}", st, city, d))
    for s in SELLERS:
        people.append((s[0], f"seller.{s[0]}", s[1], f"seed_{s[0]}"[:30], s[4], s[5], s[6]))

    w("-- 1. Accounts (auth.users + email identities). Profiles are created by the sign-up trigger.")
    for k, local, name, uname, st, city, d in people:
        u = uid(f"user/{k}")
        email = f"{local}@{DOMAIN}"
        created = ago(d * DAY + RNG.randint(0, 600))
        meta = '{"username": "%s", "display_name": "%s"}' % (uname, name.replace('"', ''))
        w("insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,")
        w("  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,")
        w("  confirmation_token, recovery_token, email_change_token_new, email_change, email_change_token_current, reauthentication_token)")
        w(f"values ('00000000-0000-0000-0000-000000000000', {q(u)}, 'authenticated', 'authenticated', {q(email)},")
        w("  extensions.crypt(coalesce(nullif(current_setting('purple.seed_password', true), ''), encode(extensions.gen_random_bytes(24), 'hex')), extensions.gen_salt('bf')),")
        w(f"  {created}, '{{\"provider\": \"email\", \"providers\": [\"email\"]}}'::jsonb, {q(meta)}::jsonb, {created}, {created},")
        w("  '', '', '', '', '', '');")
        w("insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at)")
        w(f"values ({q(uid('identity/' + k))}, {q(u)}, {q(u)}, 'email',")
        w(f"  jsonb_build_object('sub', {q(u)}, 'email', {q(email)}, 'email_verified', true, 'phone_verified', false), {created}, {created});")
        w(f"update public.profiles set created_at = (select created_at from auth.users where id = {q(u)}), state = {q(st)}, city = {q(city)} where id = {q(u)};")
    w("")

    w("-- 2. Roles and shop details")
    w(f"update public.profiles set role = 'admin' where id = {q(uid('user/admin'))};")
    for s in SELLERS:
        (k, shop, persona, cat, st, city, d, ver, mode, public, headline, bio, skills, langs, years) = s
        u = uid(f"user/{k}")
        avail = persona in ("home", "creative", "freelancer")
        w(f"update public.profiles set role = 'seller', business_name = {q(shop)}, headline = {q(headline)}, bio = {q(bio)},")
        w(f"  years_experience = {years}, is_available = {q(avail)}, skills = {q(skills)}, languages = {q(langs)},")
        w(f"  pro_mode = {q(mode)}::public.pro_mode, pro_public = {q(public)} where id = {q(u)};")
        w(f"select private.ensure_seller_register({q(u)});")
    w("")

    w("-- 3. ID verification (approved ones turn on the verified badge; required before home-service listings)")
    last4 = 1001
    for s in SELLERS:
        k, ver = s[0], s[7]
        if ver is None:
            continue
        u = uid(f"user/{k}")
        docpath = None if ver == "approved" else f"{u}/seed/id-document.jpg"
        deleted = "now() - interval '1 day'" if ver == "approved" else "null"
        reviewed = "now() - interval '2 days'" if ver in ("approved", "rejected") else "null"
        reviewer = q(uid("user/admin")) if ver in ("approved", "rejected") else "null"
        reason = "Seed: document photo is blurred." if ver == "rejected" else None
        w("insert into public.seller_verifications (user_id, status, id_type, id_document_path, id_document_deleted_at, bank_name, bank_code,")
        w("  account_name, account_last4, rejection_reason, submitted_at, reviewed_by, reviewed_at)")
        w(f"values ({q(u)}, {q(ver)}::public.verification_status, 'nin', {q(docpath)}, {deleted}, 'Seed Test Bank', '000',")
        w(f"  {q(s[1])}, '{last4}', {q(reason)}, now() - interval '3 days', {reviewer}, {reviewed});")
        last4 += 1
    w("")

    w("-- 4. Listings and image paths (files are not uploaded; see docs)")
    seller_of = {s[0]: s for s in SELLERS}
    lid = {}
    for i, row in enumerate(LISTINGS):
        sk, key, typ, title, desc, naira, starting, stock, delivery, status = row[:10]
        extra = row[10] if len(row) > 10 else {}
        s = seller_of[sk]
        u = uid(f"user/{sk}")
        l = uid(f"listing/{key}")
        lid[key] = (l, sk, naira, title, status, typ)
        created = ago((s[6] - 1) * DAY - i * 37)
        w("insert into public.listings (id, seller_id, type, category_id, title, description, price_kobo, price_is_starting, quote_on_request,")
        w("  stock, delivery_mode, state, city, status, rejection_reason, created_at, updated_at)")
        w(f"values ({q(l)}, {q(u)}, {q(typ)}::public.listing_type, {CAT[s[3]]}, {q(title)}, {q(desc)}, {naira * 100}, {q(starting)}, {q(bool(extra.get('quote')))},")
        w(f"  {q(stock) if stock is not None else 'null'}, {q(delivery)}::public.delivery_mode, {q(s[4])}, {q(s[5])}, {q(status)}::public.listing_status, {q(REJECTION.get(key))}, {created}, {created});")
        for pos in range(2 if typ == "product" else 1):
            w(f"insert into public.listing_images (listing_id, storage_path, position) values ({q(l)}, {q(f'{u}/seed/{key}-{pos}.jpg')}, {pos});")
    w("")

    w("-- 5. Home-service areas and hours; professional page entries")
    for s in SELLERS:
        k, persona = s[0], s[2]
        u = uid(f"user/{k}")
        if persona == "home":
            for city in (s[5], {"Lagos": "Ikeja", "FCT": "Gwarinpa", "Rivers": "Obio-Akpor", "Kaduna": "Zaria"}[s[4]]):
                w(f"insert into public.service_areas (seller_id, state, city) values ({q(u)}, {q(s[4])}, {q(city)});")
            for dow in range(1, 7):
                w(f"insert into public.working_hours (seller_id, day_of_week, opens_at, closes_at) values ({q(u)}, {dow}, '08:00', '{'14:00' if dow == 6 else '18:00'}');")
        if s[8]:
            entries = [
                ("experience", f"Lead at {s[1].replace(' (seed)', '')}", s[1].replace(" (seed)", ""), s[5], 2026 - s[14], None, True, "Running client projects end to end."),
                ("education", "Diploma, applied arts and technology", "Seed Polytechnic", s[4], 2026 - s[14] - 3, 2026 - s[14], False, None),
            ]
            if persona == "freelancer":
                entries.append(("certification", "Seed cloud practitioner certificate", "Seed Training Centre", None, 2025, 2025, False, None))
            for pos, (kind, title, org, loc, y0, y1, cur, d) in enumerate(entries):
                w("insert into public.pro_entries (id, owner_id, kind, title, organisation, location, start_year, end_year, is_current, description, position)")
                w(f"values ({q(uid(f'pro/{k}/{pos}'))}, {q(u)}, {q(kind)}::public.pro_entry_kind, {q(title)}, {q(org)}, {q(loc)}, {y0}, {q(y1) if y1 else 'null'}, {q(cur)}, {q(d)}, {pos});")
    w("")

    buyers = [b[0] for b in BUYERS]
    active_buyers = buyers[:9]
    B = lambda k: uid(f"user/{k}")  # noqa: E731

    w("-- 6. Purple Stories (video files are placeholders), tagged products, likes, comments, events")
    stories = [
        ("st_adire1", "adire_house", "Dyeing a fresh batch of indigo", "From the dye pot to the drying line.", 34, "published", ["adire_wrapper", "adire_shirt"]),
        ("st_adire2", "adire_house", "Three ways to tie an adire wrapper", "Quick styling ideas.", 48, "published", ["adire_wrapper"]),
        ("st_kampala", "kampala_corner", "New kampala colours this week", "Orange, teal and purple batches.", 22, "published", ["kampala_yard", "kampala_dress"]),
        ("st_clay", "clay_and_kiln", "Throwing a vase on the wheel", "Ten minutes, sped up.", 55, "published", ["clay_vase", "clay_bowls"]),
        ("st_bead", "bead_works", "Stringing a coral necklace", "Close-up of the knotting.", 41, "published", ["bead_necklace"]),
        ("st_lens1", "lens_and_light", "Behind the scenes at a naming ceremony", "Lighting set-up for indoor events.", 30, "published", []),
        ("st_lens2", "lens_and_light", "Before and after: portrait edit", "Colour grading a studio portrait.", 19, "published", []),
        ("st_pixel", "pixel_forge", "Packaging design for a juice brand", "Sketch to final box.", 27, "published", []),
        ("st_ife", "voice_by_ife", "Voice-over demo reel", "Advert, documentary and audiobook samples.", 58, "draft", []),
        ("st_drum", "drum_circle", "Wedding band highlights", "Hidden by moderation for a test case.", 45, "hidden", []),
    ]
    for i, (key, sk, title, desc, secs, status, tags) in enumerate(stories):
        u = uid(f"user/{sk}")
        v = uid(f"story/{key}")
        views = RNG.randint(40, 400) if status == "published" else 0
        created = ago((10 - i) * DAY + 300)
        pub = created if status in ("published", "hidden") else "null"
        note = "Seed: hidden after a test report." if status == "hidden" else None
        size = int(secs * 0.241 * 1024 * 1024)
        w("insert into public.story_videos (id, seller_id, title, description, category_id, video_path, thumbnail_path, duration_seconds, size_bytes,")
        w("  width, height, status, moderation_note, view_count, published_at, created_at, updated_at)")
        w(f"values ({q(v)}, {q(u)}, {q(title)}, {q(desc)}, {CAT[seller_of[sk][3]]}, {q(f'{u}/seed/{key}.mp4')}, {q(f'{u}/seed/{key}.jpg')}, {secs}, {size},")
        w(f"  720, 1280, {q(status)}::public.story_status, {q(note)}, {views}, {pub}, {created}, {created});")
        for pos, t in enumerate(tags):
            w(f"insert into public.story_video_products (video_id, listing_id, position) values ({q(v)}, {q(lid[t][0])}, {pos});")
        if status == "published":
            likers = RNG.sample(active_buyers, RNG.randint(1, 6))
            for b in likers:
                w(f"insert into public.story_likes (video_id, user_id) values ({q(v)}, {q(B(b))});")
            for j, b in enumerate(RNG.sample(active_buyers, RNG.randint(0, 3))):
                body = ["Lovely work!", "Do you deliver to Abuja?", "The colours are beautiful.", "How long does this take?"][(i + j) % 4]
                w(f"insert into public.story_comments (id, video_id, user_id, body, created_at) values ({q(uid(f'comment/{key}/{j}'))}, {q(v)}, {q(B(b))}, {q(body)}, {ago((9 - i) * DAY)});")
            for et, n in (("impression", views + 50), ("view", views // 4), ("product_click", 3 if tags else 0), ("shop_visit", 2)):
                if n:
                    w(f"insert into public.story_events (video_id, event_type, created_at) select {q(v)}, {q(et)}::public.story_event_type, now() - (g || ' minutes')::interval from generate_series(1, {min(n, 60)}) g;")
    w("")

    w("-- 7. Purple Requests and offers")
    requests = [
        ("rq_website", "tunde", "tech-freelance", "Website for a small bakery", "Menu, opening hours and an order form. Budget is flexible for the right designer.", 300000, "open", 5,
         [("devcraft", 280000, 14, "sent", "We can deliver a five-page site with an order form in two weeks."), ("tobi_dev", 250000, 21, "sent", "Happy to build this with a simple admin page.")]),
        ("rq_adire", "adaeze", "fashion-adire", "Custom adire outfit for a wedding", "Matching outfits for four people, indigo with white patterns.", 160000, "open", 4,
         [("adire_house", 150000, 10, "sent", "Four outfits in ten days. We can share fabric samples first."), ("kampala_corner", 120000, 14, "declined", "We can do this in kampala instead of adire.")]),
        ("rq_ac", "chiamaka", "home-services", "AC servicing for two split units", "Both units cool slowly. Flat in Garki.", 30000, "closed", 9,
         [("cool_air_fix", 24000, 2, "accepted", "Servicing for both units with a gas check, this week.")]),
        ("rq_logo", "ibrahim", "digital-design", "Logo and brand colours for a new shop", "Grocery shop opening next month.", 80000, "open", 7,
         [("pixel_forge", 90000, 7, "sent", "Three concepts and a colour palette within a week."), ("logo_lab", 25000, 2, "withdrawn", "Quick logo option.")]),
        ("rq_photo", "funmi", "photo-video-talent", "Photographer for a naming ceremony", "Saturday morning, about three hours, Ibadan.", 100000, "open", 3,
         [("lens_and_light", 110000, 1, "sent", "Half-day coverage with edited photos within a week.")]),
        ("rq_clean", "emeka", "home-services", "Deep cleaning after renovation", "Four-bedroom house, dust everywhere.", 70000, "expired", 20, []),
        ("rq_mc", "zainab", "photo-video-talent", "MC for a birthday party", "Evening party for about eighty guests.", 60000, "closed", 12,
         [("mc_kunle", 80000, 1, "declined", "Five hours of hosting, bilingual.")]),
        ("rq_vases", "segun", "art-crafts", "Handmade clay vases for an office", "Six medium vases for a reception area.", 150000, "open", 2,
         [("clay_and_kiln", 140000, 12, "sent", "Six vases in a matching glaze, ready in twelve days.")]),
    ]
    offer_ids = {}
    for key, bk, cat, title, desc, naira, status, days, offers in requests:
        r = uid(f"request/{key}")
        created = ago(days * DAY)
        expires = ahead((14 - days) * DAY) if status != "expired" else ago((days - 14) * DAY)
        closed = ago((days - 2) * DAY) if status == "closed" else "null"
        st, city = next((b[2], b[3]) for b in BUYERS if b[0] == bk)
        w("insert into public.buyer_requests (id, buyer_id, category_id, title, description, budget_kobo, state, city, status, created_at, expires_at, closed_at, updated_at)")
        w(f"values ({q(r)}, {q(B(bk))}, {CAT[cat]}, {q(title)}, {q(desc)}, {naira * 100}, {q(st)}, {q(city)}, {q(status)}::public.request_status, {created}, {expires}, {closed}, {created});")
        live = 0
        accepted = None
        for j, (sk, price, ddays, ost, msg) in enumerate(offers):
            o = uid(f"offer/{key}/{sk}")
            offer_ids[(key, sk)] = o
            w("insert into public.request_offers (id, request_id, seller_id, message, price_kobo, delivery_days, status, created_at, updated_at)")
            w(f"values ({q(o)}, {q(r)}, {q(uid(f'user/{sk}'))}, {q(msg)}, {price * 100}, {ddays}, {q(ost)}::public.offer_status, {ago(days * DAY - 120 - j * 60)}, {ago(days * DAY - 120 - j * 60)});")
            if ost in ("sent", "accepted"):
                live += 1
            if ost == "accepted":
                accepted = o
        w(f"update public.buyer_requests set offer_count = {live}, accepted_offer_id = {q(accepted)} where id = {q(r)};")
    w("")

    w("-- 8. Conversations and messages")
    convs = [
        ("cv_adaeze_adire", "adaeze", "adire_house", "adire_shirt", None, [
            ("b", "Hello, is the adire shirt available in size L?"), ("s", "Yes, we have L. It takes five working days."),
            ("b", "Great, I will order through the site today."), ("s", "Thank you! We will start once the order comes in.")]),
        ("cv_tunde_dev", "tunde", "devcraft", "dev_website", None, [
            ("b", "Can the website include an online menu?"), ("s", "Yes, the menu can be edited from a simple admin page.")]),
        ("cv_chiamaka_cool", "chiamaka", "cool_air_fix", None, ("rq_ac", "cool_air_fix"), [
            ("s", "Thanks for accepting. Which day works for you?"), ("b", "Thursday afternoon is best."),
            ("s", "Thursday afternoon is booked. See you then."), ("b", "Perfect, thank you.")]),
        ("cv_funmi_lens", "funmi", "lens_and_light", "lens_event", None, [
            ("b", "Do you also cover the evening reception?"), ("s", "Yes, we can extend to a full day for an extra fee.")]),
        ("cv_ngozi_clay", "ngozi", "clay_and_kiln", "clay_bowls", None, [
            ("b", "Are the bowls safe in the microwave?"), ("s", "Yes, the glaze is food and microwave safe."), ("b", "Thanks, ordering now.")]),
        ("cv_segun_spark", "segun", "spark_electric", "spark_inverter", None, [
            ("b", "How long does an inverter install take?"), ("s", "About half a day, including testing.")]),
        ("cv_zainab_ife", "zainab", "voice_by_ife", "ife_advert", None, [
            ("b", "Can you read in Hausa?"), ("s", "Not yet, only English, Yoruba and Pidgin. Sorry!")]),
        ("cv_emeka_bead", "emeka", "bead_works", "bead_necklace", None, [
            ("b", "Is the price final?"), ("s", "The price is fixed, but delivery is free in Abuja.")]),
    ]
    for i, (key, bk, sk, lkey, offer, msgs) in enumerate(convs):
        c = uid(f"conversation/{key}")
        start = (12 - i) * DAY
        last = start - 10 * (len(msgs) - 1)
        oid = offer_ids[offer] if offer else None
        w("insert into public.conversations (id, buyer_id, seller_id, listing_id, request_offer_id, created_at, last_message_at, buyer_read_at, seller_read_at)")
        w(f"values ({q(c)}, {q(B(bk))}, {q(uid(f'user/{sk}'))}, {q(lid[lkey][0]) if lkey else 'null'}, {q(oid)}, {ago(start)}, {ago(last)}, {ago(last)}, {ago(last + (5 if i % 3 == 0 else 0))});")
        for j, (who, body) in enumerate(msgs):
            sender = B(bk) if who == "b" else uid(f"user/{sk}")
            at = start - 10 * j
            read = ago(at - 2) if (j < len(msgs) - 1 or i % 3) else "null"
            w(f"insert into public.messages (id, conversation_id, sender_id, body, read_at, created_at) values ({q(uid(f'message/{key}/{j}'))}, {q(c)}, {q(sender)}, {q(body)}, {read}, {ago(at)});")
    w("")

    w("-- 9. Checkouts, orders, payouts, bookings and reviews (test records only; no payment provider involved)")
    orders = [
        ("od_adaeze", "adaeze", "adire_house", [("adire_shirt", 1)], 2500, "completed", 30, (5, "Beautiful shirt, fits well and arrived on time.", None)),
        ("od_ngozi", "ngozi", "clay_and_kiln", [("clay_bowls", 1), ("clay_planter", 2)], 3000, "completed", 9, (4, "Lovely bowls. One planter had a small chip.", "Sorry about the chip. We have sent a replacement.")),
        ("od_tunde", "tunde", "bead_works", [("bead_bracelet", 2)], 2000, "shipped", 4, None),
        ("od_funmi", "funmi", "kampala_corner", [("kampala_yard", 6)], 1500, "delivered", 6, None),
    ]
    for n, (key, bk, sk, items, fee_naira, status, days, review) in enumerate(orders, start=1):
        ck = uid(f"checkout/{key}")
        o = uid(f"order/{key}")
        subtotal = sum(lid[lk][2] * qty for lk, qty in items) * 100
        delivery = fee_naira * 100
        platform = subtotal // 10
        payout = subtotal + delivery - platform
        b = next(x for x in BUYERS if x[0] == bk)
        w("insert into public.checkouts (id, buyer_id, payment_reference, total_kobo, status, delivery_name, delivery_phone, delivery_address, delivery_city, delivery_state, paid_at, created_at)")
        w(f"values ({q(ck)}, {q(B(bk))}, {q(f'SEED-CHECKOUT-{n:04d}')}, {subtotal + delivery}, 'paid', {q(b[1])}, '+2340000000{n:03d}', {q(f'{n} Seed Test Street')}, {q(b[3])}, {q(b[2])}, {ago(days * DAY)}, {ago(days * DAY + 5)});")
        shipped = ago((days - 1) * DAY) if status in ("shipped", "delivered", "completed") else "null"
        delivered = ago((days - 3) * DAY) if status in ("delivered", "completed") else "null"
        completed = ago((days - 5) * DAY) if status == "completed" else "null"
        confirm = ahead(2 * DAY) if status == "delivered" else "null"
        w("insert into public.orders (id, checkout_id, buyer_id, seller_id, status, subtotal_kobo, delivery_fee_kobo, platform_fee_kobo, seller_payout_kobo,")
        w("  shipped_at, delivered_at, confirm_by, completed_at, created_at)")
        w(f"values ({q(o)}, {q(ck)}, {q(B(bk))}, {q(uid(f'user/{sk}'))}, {q(status)}::public.order_status, {subtotal}, {delivery}, {platform}, {payout},")
        w(f"  {shipped}, {delivered}, {confirm}, {completed}, {ago(days * DAY)});")
        for lk, qty in items:
            w(f"insert into public.order_items (order_id, listing_id, title_snapshot, unit_price_kobo, quantity) values ({q(o)}, {q(lid[lk][0])}, {q(lid[lk][3])}, {lid[lk][2] * 100}, {qty});")
        if status == "completed":
            w(f"insert into public.payouts (order_id, seller_id, amount_kobo, status, transfer_reference, paid_at) values ({q(o)}, {q(uid(f'user/{sk}'))}, {payout}, 'paid', {q(f'SEED-PAYOUT-{n:04d}')}, {ago((days - 6) * DAY)});")
        if review:
            rating, body, reply = review
            w("insert into public.reviews (id, order_id, reviewer_id, seller_id, rating, body, seller_reply, seller_replied_at, created_at)")
            w(f"values ({q(uid(f'review/{key}'))}, {q(o)}, {q(B(bk))}, {q(uid(f'user/{sk}'))}, {rating}, {q(body)}, {q(reply)}, {ago((days - 7) * DAY) if reply else 'null'}, {ago((days - 6) * DAY)});")

    bookings = [
        ("bk_segun", "segun", "spark_electric", "spark_inverter", None, "Install a 3.5 kVA inverter with two batteries.", "completed", 16, (5, "Neat work and explained everything.")),
        ("bk_chiamaka", "chiamaka", "cool_air_fix", None, ("rq_ac", "cool_air_fix"), "Service two split units, check gas.", "scheduled", -3, None),
        ("bk_ngozi", "ngozi", "clean_sweep", "clean_deep", None, "Deep clean before moving in.", "requested", -10, None),
    ]
    for key, bk, sk, lkey, offer, details, status, day_offset, review in bookings:
        bkid = uid(f"booking/{key}")
        b = next(x for x in BUYERS if x[0] == bk)
        pref = f"(now() - interval '{day_offset} days')::date"
        sched = f"now() - interval '{day_offset} days'" if status in ("scheduled", "completed") else "null"
        w("insert into public.bookings (id, buyer_id, pro_id, listing_id, request_offer_id, job_details, service_address, city, state, preferred_date, preferred_window, scheduled_at, status, created_at, updated_at)")
        w(f"values ({q(bkid)}, {q(B(bk))}, {q(uid(f'user/{sk}'))}, {q(lid[lkey][0]) if lkey else 'null'}, {q(offer_ids[offer]) if offer else 'null'}, {q(details)}, {q('Flat 2, Seed Test Close')}, {q(b[3])}, {q(b[2])}, {pref}, 'afternoon', {sched}, {q(status)}::public.booking_status, {ago(abs(day_offset) * DAY + DAY)}, {ago(abs(day_offset) * DAY + DAY)});")
        if review:
            w(f"insert into public.reviews (id, booking_id, reviewer_id, seller_id, rating, body, created_at) values ({q(uid(f'review/{key}'))}, {q(bkid)}, {q(B(bk))}, {q(uid(f'user/{sk}'))}, {review[0]}, {q(review[1])}, {ago((day_offset - 1) * DAY)});")
    w("")

    w("-- 10. Saves, follows, carts, blocks, reports, referrals, share links, notifications, searches, listing views")
    approved = [k for k, v in lid.items() if v[4] == "approved"]
    approved_products = [k for k in approved if lid[k][5] == "product"]
    for b in active_buyers:
        for lk in RNG.sample(approved, 4):
            w(f"insert into public.saves (user_id, listing_id) values ({q(B(b))}, {q(lid[lk][0])});")
        for sk in RNG.sample([s[0] for s in SELLERS if s[0] not in ("canvas_corner", "fix_it_femi")], 3):
            w(f"insert into public.follows (follower_id, seller_id) values ({q(B(b))}, {q(uid(f'user/{sk}'))});")
    for b, lk, qty in (("adaeze", "kampala_dress", 1), ("zainab", "bead_bracelet", 3), ("ibrahim", "clay_planter", 2)):
        w(f"insert into public.cart_items (user_id, listing_id, quantity) values ({q(B(b))}, {q(lid[lk][0])}, {qty});")
    w(f"insert into public.user_blocks (blocker_id, blocked_id) values ({q(B('ngozi'))}, {q(B('musa'))});")
    w(f"insert into public.reports (id, reporter_id, listing_id, reason, details) values ({q(uid('report/listing'))}, {q(B('zainab'))}, {q(lid['canvas_lagos'][0])}, 'misleading', 'Seed report: the size in the photos looks different.');")
    w(f"insert into public.reports (id, reporter_id, request_id, reason, details) values ({q(uid('report/request'))}, {q(B('tunde'))}, {q(uid('request/rq_vases'))}, 'other', 'Seed report on a request.');")
    w(f"insert into public.reports (id, reporter_id, reported_user_id, reason, details, status, handled_by, handled_at, resolution_note) values ({q(uid('report/user'))}, {q(B('ngozi'))}, {q(B('musa'))}, 'harassment', 'Seed report: rude messages.', 'actioned', {q(uid('user/admin'))}, now() - interval '9 days', 'Seed: account banned.');")
    w(f"insert into public.referrals (referrer_id, referred_id, reward_status) values ({q(B('adaeze'))}, {q(B('chiamaka'))}, 'pending');")
    w(f"insert into public.share_links (id, code, listing_id, created_by, clicks) values ({q(uid('share/adaeze'))}, 'seedshare1', {q(lid['adire_wrapper'][0])}, {q(B('adaeze'))}, 7);")
    notes = [
        ("adire_house", "new_message", "New message", "Adaeze asked about the adire shirt."),
        ("tunde", "request_offer", "New offer on your request", "DevCraft Studio sent an offer."),
        ("ngozi", "order_update", "Order delivered", "Your order from Clay and Kiln was delivered."),
        ("devcraft", "listing_review", "Listing in review", "Website speed check is waiting for review."),
        ("mc_kunle", "verification_update", "ID check not approved", "Please upload a clearer photo of your document."),
    ]
    for i, (who, typ, title, body) in enumerate(notes):
        w(f"insert into public.notifications (id, recipient_id, type, title, body, created_at) values ({q(uid(f'notification/{i}'))}, {q(uid(f'user/{who}'))}, {q(typ)}::public.notification_type, {q(title)}, {q(body)}, {ago((i + 1) * 300)});")
    for i, (query, cat, n) in enumerate((("adire", 1, 3), ("ankara", 1, 0), ("website", 5, 2), ("logo", 3, 2), ("ac repair", 6, 2),
                                         ("photographer", 4, 2), ("vase", 2, 1), ("electrician", 6, 1), ("bead necklace", 2, 1), ("voice over", 4, 2))):
        w(f"insert into public.search_queries (query, category_id, results_count, created_at) values ({q(query)}, {cat}, {n}, {ago(i * 400 + 30)});")
    for lk in approved_products[:6]:
        w(f"insert into public.listing_events (listing_id, event_type, created_at) select {q(lid[lk][0])}, 'view', now() - (g || ' hours')::interval from generate_series(1, {RNG.randint(3, 20)}) g;")
    w("")

    w("-- 11. Account states for test cases (last, so earlier inserts are not blocked)")
    w(f"update public.profiles set account_status = 'banned', status_reason = 'Seed: banned test account' where id = {q(B('musa'))};")
    w(f"update public.profiles set account_status = 'suspended', status_reason = 'Seed: suspended test account', suspended_until = now() + interval '7 days' where id = {q(B('bisi'))};")
    w(f"update public.profiles set account_status = 'suspended', status_reason = 'Seed: suspended test shop', suspended_until = now() + interval '14 days' where id = {q(uid('user/canvas_corner'))};")
    w(f"update public.profiles set deletion_requested_at = now() - interval '2 days' where id = {q(B('kelechi'))};")
    w("")
    w("-- End of seed.")
    return "\n".join(out) + "\n"


def main():
    sql = build()
    if "--check" in sys.argv:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != sql:
            print("supabase/seed.sql is out of date: run python3 supabase/tools/seed/generate_seed.py")
            sys.exit(1)
        print("supabase/seed.sql is up to date")
        return
    OUT.write_text(sql, encoding="utf-8", newline="\n")
    print(f"wrote {OUT.relative_to(ROOT)} ({len(sql.encode())} bytes)")


if __name__ == "__main__":
    main()
