-- =============================================================================
-- SMART NAGPUR — Create Field Staff / Supervisor Accounts
-- =============================================================================
-- Run this in Supabase Dashboard → SQL Editor to create field staff accounts.
-- You can edit the parameters in the DECLARE block below:
-- =============================================================================

DO $$
DECLARE
  -- Configure your new staff member here:
  v_staff_name       text := 'Ramesh Sharma';
  v_staff_email      text := 'ramesh.road@nagpur.gov.in';
  v_staff_password   text := 'StaffPassword123!';
  v_staff_phone      text := '+919876500001';
  v_employee_id      text := 'NMC-RD-101';
  v_department       text := 'ROAD';          -- Options: 'ROAD', 'WASTE', 'WATER', 'VENDOR', 'GENERAL'
  v_role             text := 'FIELD_WORKER';  -- Options: 'FIELD_WORKER', 'SUPERVISOR', 'OFFICER'
  v_zone             text := 'Dharampeth';
  v_ward             text := 'Ward 12';

  -- Internal variables
  v_user_id          uuid;
  v_encrypted_pw     text := extensions.crypt(v_staff_password, extensions.gen_salt('bf'));
BEGIN
  -- 1. Check if auth account already exists
  SELECT id INTO v_user_id FROM auth.users WHERE email = lower(trim(v_staff_email));

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();

    -- Create user in auth.users
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
  ELSE
    -- Update existing password and confirm email
    UPDATE auth.users
    SET encrypted_password = v_encrypted_pw,
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        raw_app_meta_data = '{"provider": "email", "providers": ["email"]}'::jsonb,
        raw_user_meta_data = jsonb_build_object('name', v_staff_name, 'role', v_role, 'department', v_department),
        is_sso_user = false,
        updated_at = now()
    WHERE id = v_user_id;
  END IF;

  -- 2. Ensure identity exists in auth.identities (Required for GoTrue email password login)
  DELETE FROM auth.identities WHERE user_id = v_user_id;
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
    v_user_id::text,
    v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', lower(trim(v_staff_email)), 'email_verified', true),
    'email',
    v_user_id::text,
    now(),
    now(),
    now()
  );

  -- 3. Upsert into public.profiles
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

  -- 4. Upsert into public.staff_profiles
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
  RAISE NOTICE '✅ STAFF ACCOUNT CREATED AND READY FOR LOGIN!';
  RAISE NOTICE 'Name:        %', v_staff_name;
  RAISE NOTICE 'Email:       %', lower(trim(v_staff_email));
  RAISE NOTICE 'Password:    %', v_staff_password;
  RAISE NOTICE 'Employee ID: %', v_employee_id;
  RAISE NOTICE 'Department:  %', v_department;
  RAISE NOTICE 'Role:        %', v_role;
  RAISE NOTICE '=======================================================';
END $$;
