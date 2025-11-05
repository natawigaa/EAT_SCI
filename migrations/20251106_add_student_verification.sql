-- Migration: add student verification fields and helper functions
-- Run this as DB owner (psql or Supabase SQL editor)

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS is_student_verified boolean DEFAULT false;

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS verification_method text;

-- Helper function: set is_student_verified based on email domain
-- Call this function after creating a student profile or from an auth webhook
CREATE OR REPLACE FUNCTION public.set_student_verified_for_email(p_user_id uuid, p_email text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_email IS NULL THEN
    RETURN;
  END IF;

  IF lower(split_part(p_email, '@', 2)) = 'kmitl.ac.th' THEN
    UPDATE public.students
      SET is_student_verified = true,
          verification_method = 'google_or_email_domain'
    WHERE id = p_user_id;
  ELSE
    -- keep default false
    RETURN;
  END IF;
END;
$$;

-- Optional RPC to mark a student verified manually (for admin review)
CREATE OR REPLACE FUNCTION public.mark_student_verified(p_user_id uuid, p_method text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.students
    SET is_student_verified = true,
        verification_method = p_method
  WHERE id = p_user_id;
END;
$$;

-- Note: To automatically call set_student_verified_for_email when a new
-- auth user signs up, you can create a trigger on auth.users that calls a
-- webhook or inserts/updates the students table. Many Supabase projects
-- prefer handling this in an Edge Function or server-side webhook because
-- triggers on auth schema require elevated privileges. Run the RPC
-- manually or wire it into your signup flow.
