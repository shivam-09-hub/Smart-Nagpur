-- Complete robust function to create staff accounts that GoTrue can authenticate seamlessly
CREATE OR REPLACE FUNCTION public.admin_create_staff_account(
  p_name text,
  p_email text,
  p_password text,
  p_phone text DEFAULT '',
  p_employee_id text DEFAULT '',
  p_department text DEFAULT 'ROAD',
  p_role text DEFAULT 'FIELD_WORKER',
  p_zone text DEFAULT 'ALL',
  p_ward text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id uuid := auth.uid();
  v_new_user_id uuid := gen_random_uuid();
  v_norm_email text := lower(trim(p_email));
  v_emp_id text;
  v_encrypted_pw text;
  v_staff_row record;
  v_now timestamptz := now();
BEGIN
  -- 1. Authorization: Only active Admins can create staff accounts
  IF NOT public.is_active_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only Municipal Administrators can create staff accounts.';
  END IF;

  -- 2. Validate parameters
  IF v_norm_email = '' OR p_name = '' OR p_password = '' THEN
    RAISE EXCEPTION 'Staff name, email, and password are required.';
  END IF;

  IF length(p_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters.';
  END IF;

  IF p_department NOT IN ('ROAD', 'WASTE', 'WATER', 'VENDOR', 'GENERAL') THEN
    RAISE EXCEPTION 'Invalid department. Allowed: ROAD, WASTE, WATER, VENDOR, GENERAL.';
  END IF;

  IF p_role NOT IN ('FIELD_WORKER', 'SUPERVISOR', 'OFFICER') THEN
    RAISE EXCEPTION 'Invalid role. Allowed: FIELD_WORKER, SUPERVISOR, OFFICER.';
  END IF;

  -- Generate employee ID if empty
  IF p_employee_id IS NULL OR trim(p_employee_id) = '' THEN
    v_emp_id := 'NMC-' || p_department || '-' || upper(substr(gen_random_uuid()::text, 1, 6));
  ELSE
    v_emp_id := trim(p_employee_id);
  END IF;

  -- 3. Check for duplicates in staff_profiles
  IF EXISTS (SELECT 1 FROM public.staff_profiles WHERE email = v_norm_email) THEN
    RAISE EXCEPTION 'A staff member with email % already exists.', v_norm_email;
  END IF;

  IF EXISTS (SELECT 1 FROM public.staff_profiles WHERE employee_id = v_emp_id) THEN
    RAISE EXCEPTION 'A staff member with Employee ID % already exists.', v_emp_id;
  END IF;

  -- 4. Check if user already exists in auth.users
  SELECT id INTO v_new_user_id FROM auth.users WHERE email = v_norm_email;
  v_encrypted_pw := extensions.crypt(p_password, extensions.gen_salt('bf', 10));

  IF v_new_user_id IS NULL THEN
    v_new_user_id := gen_random_uuid();
    
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      invited_at,
      confirmation_token,
      confirmation_sent_at,
      recovery_token,
      recovery_sent_at,
      email_change_token_new,
      email_change,
      email_change_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      created_at,
      updated_at,
      phone,
      phone_confirmed_at,
      phone_change,
      phone_change_token,
      phone_change_sent_at,
      confirmed_at,
      email_change_token_current,
      email_change_confirm_status,
      banned_until,
      reauthentication_token,
      reauthentication_sent_at,
      is_sso_user,
      deleted_at,
      is_anonymous
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_new_user_id,
      'authenticated',
      'authenticated',
      v_norm_email,
      v_encrypted_pw,
      v_now,
      null,
      '',
      null,
      '',
      null,
      '',
      '',
      null,
      null,
      '{"provider": "email", "providers": ["email"]}'::jsonb,
      jsonb_build_object('name', p_name, 'role', p_role, 'department', p_department),
      false,
      v_now,
      v_now,
      null,
      null,
      '',
      '',
      null,
      v_now,
      '',
      0,
      null,
      '',
      null,
      false,
      null,
      false
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = v_encrypted_pw,
        email_confirmed_at = coalesce(email_confirmed_at, v_now),
        confirmed_at = coalesce(confirmed_at, v_now),
        email_change_confirm_status = coalesce(email_change_confirm_status, 0),
        raw_app_meta_data = '{"provider": "email", "providers": ["email"]}'::jsonb,
        raw_user_meta_data = jsonb_build_object('name', p_name, 'role', p_role, 'department', p_department),
        is_sso_user = false,
        is_anonymous = false,
        updated_at = v_now
    WHERE id = v_new_user_id;
  END IF;

  -- 5. Insert / Upsert into auth.identities
  DELETE FROM auth.identities WHERE user_id = v_new_user_id;
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
    v_new_user_id,
    v_new_user_id,
    jsonb_build_object('sub', v_new_user_id::text, 'email', v_norm_email, 'email_verified', true),
    'email',
    v_new_user_id::text,
    v_now,
    v_now,
    v_now
  );

  -- 6. Upsert into public.profiles
  INSERT INTO public.profiles (
    id,
    name,
    email,
    phone,
    created_at,
    updated_at
  ) VALUES (
    v_new_user_id,
    p_name,
    v_norm_email,
    p_phone,
    v_now,
    v_now
  )
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      email = EXCLUDED.email,
      phone = EXCLUDED.phone,
      updated_at = v_now;

  -- 7. Insert into public.staff_profiles
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
    created_by,
    created_at,
    updated_at
  ) VALUES (
    v_new_user_id,
    p_name,
    p_phone,
    v_norm_email,
    v_emp_id,
    p_department,
    p_role,
    coalesce(nullif(trim(p_zone), ''), 'ALL'),
    coalesce(trim(p_ward), ''),
    true,
    true,
    v_caller_id,
    v_now,
    v_now
  )
  RETURNING * INTO v_staff_row;

  RETURN jsonb_build_object(
    'success', true,
    'staff', row_to_json(v_staff_row)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_staff_account(text, text, text, text, text, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_staff_account(text, text, text, text, text, text, text, text, text) TO authenticated;
