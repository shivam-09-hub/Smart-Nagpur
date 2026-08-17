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
  -- Check if user already exists in auth.users
  SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
  
  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();
    
    -- 1. Insert into auth.users
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
      created_at,
      updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      v_email,
      v_encrypted_pw,
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"name":"Super Administrator"}'::jsonb,
      now(),
      now()
    );
  ELSE
    -- Update existing user's password
    UPDATE auth.users
    SET encrypted_password = v_encrypted_pw,
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now()
    WHERE id = v_user_id;
  END IF;

  -- 2. Insert or update in admin_profiles
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
    v_email,
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
