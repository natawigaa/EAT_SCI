-- Example pg_cron job to run the clear_manual_overrides function every 5 minutes
-- NOTE: pg_cron must be installed and enabled on your Postgres instance.
-- Run this once in the DB to schedule (Supabase customers: check if your plan supports pg_cron).

/*
  pg_cron example (KEEP FOR REFERENCE)

  This file contains an example `pg_cron` schedule that calls
  `public.clear_manual_overrides()` every 5 minutes. IMPORTANT:

  - Most managed Postgres / Supabase instances do NOT have pg_cron
    installed by default. Attempting to run the `cron.schedule(...)`
    call will fail with "schema \"cron\" does not exist" unless
    the extension is installed and available in your database.

  - For Supabase-managed projects we RECOMMEND using an Edge Function
    (or external scheduler) to call the RPC instead of pg_cron. See
    `docs/scheduler-readme.md` for a complete deployment + scheduling
    guide (Edge Function + Service Role Key approach).

  Keep this file as an example only. If you have admin control over
  your Postgres instance and can install extensions, you may use the
  SQL below to schedule the job.

  To schedule (example):

    SELECT cron.schedule(
      'clear_manual_overrides_every_5m',
      '*/5 * * * *',
      $$
        SELECT public.clear_manual_overrides();
      $$
    );

  To unschedule:
    SELECT cron.unschedule('clear_manual_overrides_every_5m');

*/
