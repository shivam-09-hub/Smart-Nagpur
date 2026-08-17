-- ============================================================
-- SMART NAGPUR — Create Super Admin Account
-- ============================================================
-- Run this in Supabase Dashboard → SQL Editor to create your
-- Admin Login Credentials:
--
-- Email:    admin@smartnagpur.gov.in
-- Password: AdminPassword123!
-- Role:     superAdmin
-- ============================================================

DO $$
DECLARE
  v_user_id uuid;
  v_email text := 'admin@smartnagpur.gov.in';
  v_password text := 'AdminPassword123!';
  v_encrypted_pw text := extensions.crypt(v_password, extensions.gen_salt('bf'));
BEGIN
  -- 1. Check if user already exists in auth.users
  SELECT id INTO v_user_id FROM auth.users WHERE email = lower(trim(v_email));
  
  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();
    
    -- Insert into auth.users
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
      lower(trim(v_email)),
      v_encrypted_pw,
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"name":"Super Administrator"}'::jsonb,
      false,
      false,
      now(),
      now()
    );
  ELSE
    -- Update existing user's password
    UPDATE auth.users
    SET encrypted_password = v_encrypted_pw,
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
        raw_user_meta_data = '{"name":"Super Administrator"}'::jsonb,
        is_sso_user = false,
        updated_at = now()
    WHERE id = v_user_id;
  END IF;

  -- 2. Ensure identity in auth.identities
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
    jsonb_build_object('sub', v_user_id::text, 'email', lower(trim(v_email)), 'email_verified', true),
    'email',
    v_user_id::text,
    now(),
    now(),
    now()
  );

  -- 3. Insert or update in admin_profiles
  INSERT INTO public.admin_profiles (
    id,
    name,
    email,
    phone,
    role,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    'Super Administrator',
    lower(trim(v_email)),
    '+91 712 2567890',
    'superAdmin',
    true,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE 
  SET is_active = true, role = 'superAdmin';

  RAISE NOTICE 'Super Admin user ready: % with password %', v_email, v_password;
END;
$$;
