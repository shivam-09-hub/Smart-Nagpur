-- Clean up corrupted old test accounts from auth and public tables
DO $$
DECLARE
  v_corrupt_id uuid;
BEGIN
  -- Find old broken accounts with @nagpur.gov.in
  FOR v_corrupt_id IN (
    SELECT id FROM auth.users WHERE email LIKE '%@nagpur.gov.in'
  ) LOOP
    DELETE FROM public.complaint_evidence WHERE staff_id = v_corrupt_id;
    DELETE FROM public.complaint_assignments WHERE staff_id = v_corrupt_id;
    DELETE FROM public.staff_profiles WHERE id = v_corrupt_id;
    DELETE FROM public.profiles WHERE id = v_corrupt_id;
    DELETE FROM auth.identities WHERE user_id = v_corrupt_id;
    DELETE FROM auth.users WHERE id = v_corrupt_id;
  END LOOP;
END $$;
