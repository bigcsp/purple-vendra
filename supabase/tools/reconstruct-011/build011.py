import re, sys
import os; W=os.path.dirname(os.path.abspath(__file__))+'/'
def body(path):
    t=open(path).read()
    i=t.index('AS $function$')+len('AS $function$'); j=t.rindex('$function$')
    return t[i:j]
exp=body(W+'production-fn/export_my_data.sql')
# --- undo later patches (exact text inserted by 022, 021, 016, 012) ---
def cut(text, start_key, end_key):
    a=text.index(start_key); b=text.index(end_key)
    assert a<b; return text[:a]+text[b:]
exp=cut(exp,"    'professional_page',","    'security_events_about_you',")   # 022
exp=cut(exp,"    'seller_record',","    'security_events_about_you',")       # 021
exp=cut(exp,"    'people_you_blocked',","    'security_events_about_you',")   # 016
exp=exp.replace('Everything Purple Shop holds','Everything Purple Vendra holds') # 016 rename
exp=cut(exp,"    'stories',","    'security_events_about_you',")              # 012
pad=body(W+'production-fn/process_account_deletion.sql')
old="o.bucket_id in ('id-documents', 'listing-images', 'story-media')"
assert pad.count(old)==1
pad=pad.replace(old,"o.bucket_id in ('id-documents', 'listing-images')")      # 012
fns={
 'queue_file_deletion':("public.queue_file_deletion(p_bucket text, p_name text, p_reason text)","returns void language sql security definer set search_path = ''",body(W+'production-fn/queue_file_deletion.sql')),
 'process_account_deletion':("public.process_account_deletion(uid uuid)","returns text language plpgsql security definer set search_path = ''",pad),
 'request_account_deletion':("public.request_account_deletion(confirm_username text)","returns timestamp with time zone language plpgsql security definer set search_path = ''",body(W+'production-fn/request_account_deletion.sql')),
 'cancel_account_deletion':("public.cancel_account_deletion()","returns void language plpgsql security definer set search_path = ''",body(W+'production-fn/cancel_account_deletion.sql')),
 'export_my_data':("public.export_my_data()","returns jsonb language plpgsql security definer set search_path = ''",exp),
 'run_privacy_retention':("public.run_privacy_retention()","returns jsonb language plpgsql security definer set search_path = ''",body(W+'production-fn/run_privacy_retention.sql')),
}
out=[open(W+'011_header.sql').read()]
for k in ['queue_file_deletion','process_account_deletion','request_account_deletion','cancel_account_deletion','export_my_data','run_privacy_retention']:
    sig,attrs,b=fns[k]
    out.append(f"create or replace function {sig}\n{attrs}\nas $function${b}$function$;\n")
out.append(open(W+'011_footer.sql').read())
sys.stdout.write("\n".join(out))
