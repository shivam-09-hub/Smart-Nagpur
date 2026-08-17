-- =============================================================================
-- SMART NAGPUR — 100% Automated Staff Account Creation Query
-- =============================================================================
-- Run this in Supabase Dashboard → SQL Editor. It automatically cleans up any
-- old records, creates auth credentials, identity, profile, and staff records.
-- =============================================================================

DO $$
DECLARE
  v_staff_name       text := 'Ramesh Sharma';
  v_staff_email      text := 'ramesh.road@nagpur.gov.in';
  v_staff_password   text := 'StaffPassword123!';
  v_staff_phone      text := '+919876500001';
  v_employee_id      text := 'NMC-RD-101';
  v_department       text := 'ROAD';
  v_role             text := 'FIELD_WORKER';
  v_zone             text := 'Dharampeth';
  v_ward             text := 'Ward 12';

  v_user_id          uuid := gen_random_uuid();
  v_encrypted_pw     text := extensions.crypt(v_staff_password, extensions.gen_salt('bf', 10));
BEGIN
  -- 1. Clean up any existing broken entries cleanly
  DELETE FROM public.complaint_assignments WHERE staff_id IN (SELECT id FROM auth.users WHERE email = lower(trim(v_staff_email)));
  DELETE FROM public.complaint_evidence WHERE staff_id IN (SELECT id FROM auth.users WHERE email = lower(trim(v_staff_email)));
  DELETE FROM public.staff_profiles WHERE email = lower(trim(v_staff_email));
  DELETE FROM public.profiles WHERE email = lower(trim(v_staff_email));
  DELETE FROM auth.identities WHERE user_id IN (SELECT id FROM auth.users WHERE email = lower(trim(v_staff_email)));
  DELETE FROM auth.users WHERE email = lower(trim(v_staff_email));

  -- 2. Insert into auth.users with confirmed email
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_sso_user,
    is_anonymous,
    created_at,
    updated_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_user_id,
    'authenticated',
    'authenticated',
    lower(trim(v_staff_email)),
    v_encrypted_pw,
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    jsonb_build_object('name', v_staff_name, 'role', v_role, 'department', v_department),
    false,
    false,
    now(),
    now()
  );

  -- 3. Insert into auth.identities
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', lower(trim(v_staff_email)), 'email_verified', true),
    'email',
    v_user_id::text,
    now(),
    now(),
    now()
  );

  -- 4. Upsert into public.profiles (handles auto-created trigger row)
  INSERT INTO public.profiles (
    id,
    name,
    email,
    phone,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    v_staff_name,
    lower(trim(v_staff_email)),
    v_staff_phone,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      email = EXCLUDED.email,
      phone = EXCLUDED.phone,
      updated_at = now();

  -- 5. Upsert into public.staff_profiles
  INSERT INTO public.staff_profiles (
    id,
    name,
    phone,
    email,
    employee_id,
    department,
    role,
    zone,
    ward,
    is_active,
    is_on_duty,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    v_staff_name,
    v_staff_phone,
    lower(trim(v_staff_email)),
    v_employee_id,
    v_department,
    v_role,
    v_zone,
    v_ward,
    true,
    true,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      phone = EXCLUDED.phone,
      email = EXCLUDED.email,
      employee_id = EXCLUDED.employee_id,
      department = EXCLUDED.department,
      role = EXCLUDED.role,
      zone = EXCLUDED.zone,
      ward = EXCLUDED.ward,
      is_active = true,
      is_on_duty = true,
      updated_at = now();

  RAISE NOTICE '=======================================================';
  RAISE NOTICE '🎉 STAFF USER SUCCESSFULLY CREATED & LINKED!';
  RAISE NOTICE 'User ID:     %', v_user_id;
  RAISE NOTICE 'Email:       %', lower(trim(v_staff_email));
  RAISE NOTICE 'Password:    %', v_staff_password;
  RAISE NOTICE 'Department:  %', v_department;
  RAISE NOTICE 'Role:        %', v_role;
  RAISE NOTICE '=======================================================';
END $$;
