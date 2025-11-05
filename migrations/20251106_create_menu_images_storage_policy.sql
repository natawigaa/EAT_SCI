-- Migration: Create RLS policy for menu_images bucket
-- NOTE: You MUST run this as the database owner. Running as a non-owner will raise
-- the error: "ERROR: 42501: must be owner of table objects".
--
-- How to run (recommended):
-- 1. In Supabase dashboard -> Settings -> Database -> Connection string, copy the
--    Postgres connection string (the one for the 'postgres' user or the owner).
-- 2. From PowerShell on your machine (psql must be installed):
--    psql "postgresql://<POSTGRES_USER>:<PASSWORD>@<HOST>:5432/postgres" -f migrations/20251106_create_menu_images_storage_policy.sql
--
-- Quick alternative for testing: make the bucket public via Supabase Dashboard
--    (Storage -> Buckets -> select 'menu_images' -> Edit -> Public) — this avoids
--    changing RLS and is OK for testing but not private storage.

DO $$
BEGIN
  -- If a matching policy doesn't already exist, create one for the menu_images bucket.
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'allow_menu_images_authenticated'
  ) THEN
    -- Ensure RLS is enabled for storage.objects
    ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

    -- Policy: allow authenticated users to SELECT/INSERT/UPDATE/DELETE objects
    -- that belong to the menu_images bucket. Adjust the role checks if you have
    -- special roles in your project.
    CREATE POLICY allow_menu_images_authenticated
      ON storage.objects
      FOR ALL
      USING (
        bucket_id = 'menu_images' AND (
          auth.role() = 'authenticated' OR auth.role() = 'service_role'
        )
      )
      WITH CHECK (
        bucket_id = 'menu_images' AND (
          auth.role() = 'authenticated' OR auth.role() = 'service_role'
        )
      );
  END IF;
END
$$;

-- End of migration
