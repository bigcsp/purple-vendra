
-- ---------- Function access -------------------------------------------
-- Signed-in users may request, cancel and export; the rest is internal.
revoke execute on function public.request_account_deletion(text), public.cancel_account_deletion(),
  public.export_my_data()
  from public, anon;
grant execute on function public.request_account_deletion(text), public.cancel_account_deletion(),
  public.export_my_data()
  to authenticated;
revoke execute on function public.queue_file_deletion(text, text, text), public.process_account_deletion(uuid),
  public.run_privacy_retention()
  from public, anon, authenticated;

-- ---------- Scheduled jobs ---------------------------------------------
select cron.schedule('privacy-retention', '15 2 * * *', 'select public.run_privacy_retention()');

do $$
declare
  base text := coalesce(
    (select decrypted_secret from vault.decrypted_secrets where name = 'project_url'),
    'http://127.0.0.1:54321');
begin
  perform cron.schedule('storage-cleanup', '45 2 * * *', format($cmd$
  select net.http_post(
    url := '%s/functions/v1/storage-cleanup',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb)
$cmd$, base));
end $$;
