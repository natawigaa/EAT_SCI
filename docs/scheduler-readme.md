## Scheduler / Cleanup for manual open/close overrides

หมายเหตุสำคัญ: โปรเจกต์นี้ใช้การตัดสินใจแบบ "manual override persists" — นั่นคือ ถ้าเจ้าของร้านกดเปิด/ปิดด้วยตนเอง การตั้งค่านั้นจะคงอยู่จนกว่าจะยกเลิกโดยเจ้าของร้านเอง (ไม่มีการตั้งเวลาอัตโนมัติให้ revert)

ส่วนด้านล่างนี้เป็นคำแนะนำสำหรับผู้ที่ต้องการเปิดใช้งาน scheduler (Edge Function หรือ pg_cron) เป็นทางเลือกเสริม — แต่สำหรับการใช้งานปัจจุบัน **ไม่จำเป็นต้องตั้ง scheduler** เพราะระบบจะใช้ helper compute-on-read (`getRestaurantEffectiveIsOpen`) เพื่อคำนวณสถานะ (manual > schedule > stored).

Prerequisites
- Supabase project (you own or have permissions to deploy Functions)
- Supabase CLI installed and logged in locally (optional but convenient)
- Service Role Key (from Supabase Project Settings → API) — store as a secret in Supabase
- The repository already includes:
  - `supabase_add_restaurant_schedule_and_manual_override.sql` (migration to add columns)
  - `supabase_rpc_clear_manual_overrides.sql` (RPC implementation)
  - `functions/clear_manual_overrides/index.ts` (Edge Function example)

High-level steps
1. Apply DB migration and RPC
   - Open Supabase SQL editor (or use psql) and run:
     - `supabase_add_restaurant_schedule_and_manual_override.sql`
     - `supabase_rpc_clear_manual_overrides.sql`

   This adds the manual override columns and creates the `public.clear_manual_overrides()` function.

2. Deploy Edge Function
   - Ensure `functions/clear_manual_overrides/` exists in repo (example file provided).
   - Login & link your project with Supabase CLI (PowerShell examples below).

   PowerShell example (replace <PROJECT_REF> and keys):

```powershell
# login once
supabase login

# link the local folder to your project (optional but helpful)
supabase link --project-ref <PROJECT_REF>

# set service role key as a secret (do NOT use anon key)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="<SERVICE_ROLE_KEY>"

# deploy the function (run from repo root or functions/clear_manual_overrides)
supabase functions deploy clear_manual_overrides
```

3. Schedule the function
- In the Supabase Dashboard: Functions → Schedules → Create schedule
  - Name: `clear_manual_overrides_every_5m` (or similar)
  - Frequency: every 5 minutes (or choose 1–5m depending on desired latency)
  - Target function: `clear_manual_overrides`

  Alternatively, use the Dashboard's scheduling UI to set timezone/cron expression.

4. Verify
- Check function logs in Supabase Dashboard after a scheduled run.
- Confirm DB changes:

```sql
SELECT * FROM restaurant_open_history
ORDER BY created_at DESC
LIMIT 10;

-- Check restaurants rows that previously had manual_override_expires in the past
SELECT id, is_open_manual, manual_override_expires FROM restaurants
WHERE manual_override_expires IS NOT NULL
ORDER BY manual_override_expires DESC
LIMIT 20;
```

Performance & tuning notes
- Use an index on `manual_override_expires` to make the RPC query scalable.
- If many rows may expire at once, implement batching in the RPC (LIMIT + loop) to avoid long-running transactions.
- Scheduler frequency: 1–5 minutes is a good trade-off between freshness and cost.

Security
- Store the Service Role Key as a secret in Supabase only; do not embed it in client apps.
- The Edge Function should use the Service Role Key to call the RPC — that RPC should be written to perform controlled UPDATEs and audit writes.

Rollback / alternatives
- If you prefer not to run scheduled background jobs, you may continue to use compute-on-read helper (`getRestaurantEffectiveIsOpen`) — no cron needed. See code comments in `lib/services/supabase_service.dart`.

Troubleshooting
- If `supabase functions deploy` fails, check your CLI version and that you are linked to the correct project.
- If scheduled runs don't appear in logs, ensure the schedule exists in the Dashboard and the function has correct permissions and secrets.

If you want, I can:
- generate a small `scripts/` PowerShell helper to deploy and verify the function, or
- update repo to add an example `workflow` or CI job that triggers the function if you prefer GitHub Actions scheduling.

---
Created to support Option B (Edge Function scheduler). If you'd like, I can now:
- add a small PowerShell script to deploy + test the function, and
- annotate or move the `supabase_pgcron_clear_manual_overrides.sql` file to `examples/` (already annotated).

Database cleanup / removing expiry column
---------------------------------------
If you decided to remove the expiry column entirely (the project currently
uses persistent manual overrides), there's a migration in the repo:

  - `supabase_remove_manual_override_expires.sql` — clears existing expiry values,
    drops an example index if present, and drops the `manual_override_expires`
    column from `restaurants`.

Run the migration only after taking a backup of your database (or the
`restaurants` table). The migration is destructive and irreversible.

