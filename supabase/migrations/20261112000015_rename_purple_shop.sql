-- 015 · Marketplace renamed to Purple Shop: update the two messages people can see.
do $$
declare d text;
begin
  d := pg_get_functiondef('public.protect_story_video()'::regprocedure);
  d := replace(d, 'Purple Vendra team', 'Purple Shop team');
  execute d;
end $$;
