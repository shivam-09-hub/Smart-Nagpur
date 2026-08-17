-- Upgrade assign_complaint, suspend_user, and reactivate_user to accept flexible text inputs
-- (Resolves both UUIDs and human-readable IDs like "NAG-2026-000033" or emails)

CREATE OR REPLACE FUNCTION public.assign_complaint(
  p_complaint_id text,
  p_staff_id text,
  p_priority text DEFAULT 'medium',
  p_instructions text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_complaint_uuid uuid;
  v_staff_uuid uuid;
  v_complaint record;
  v_staff record;
  v_prev_assignment_id uuid;
  v_new_assignment_id uuid;
  v_result jsonb;
BEGIN
  -- 1. Authorization
  IF NOT public.is_active_admin() THEN
    RAISE EXCEPTION 'Access denied. Caller is not an active municipal administrator.';
  END IF;

  -- 2. Resolve Complaint UUID (from UUID or public_id like NAG-2026-000033)
  IF p_complaint_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    SELECT * INTO v_complaint FROM public.complaints WHERE id = p_complaint_id::uuid;
  ELSE
    SELECT * INTO v_complaint FROM public.complaints WHERE public_id = p_complaint_id;
  END IF;

  IF v_complaint.id IS NULL THEN
    RAISE EXCEPTION 'Complaint with ID % does not exist.', p_complaint_id;
  END IF;
  v_complaint_uuid := v_complaint.id;

  -- 3. Resolve Staff UUID (from UUID or email or employee_id)
  IF p_staff_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    SELECT * INTO v_staff FROM public.staff_profiles WHERE id = p_staff_id::uuid;
  ELSE
    SELECT * INTO v_staff FROM public.staff_profiles WHERE email = lower(trim(p_staff_id)) OR employee_id = trim(p_staff_id);
  END IF;

  IF v_staff.id IS NULL THEN
    RAISE EXCEPTION 'Staff member with ID % does not exist.', p_staff_id;
  END IF;
  v_staff_uuid := v_staff.id;

  IF NOT v_staff.is_active THEN
    RAISE EXCEPTION 'Cannot assign complaint to inactive staff member.';
  END IF;

  -- 4. Department match check
  IF v_staff.department <> 'GENERAL' THEN
    IF (v_complaint.service_type = 'roads' AND v_staff.department <> 'ROAD') OR
       (v_complaint.service_type IN ('garbage', 'drainage') AND v_staff.department <> 'WASTE') OR
       (v_complaint.service_type = 'water' AND v_staff.department <> 'WATER') OR
       (v_complaint.service_type = 'vendor' AND v_staff.department <> 'VENDOR') THEN
      RAISE EXCEPTION 'Department mismatch: Complaint with service_type "%" cannot be assigned to staff in "%" department.',
        v_complaint.service_type, v_staff.department;
    END IF;
  END IF;

  -- 5. Priority validation
  IF p_priority NOT IN ('low', 'medium', 'high', 'urgent') THEN
    RAISE EXCEPTION 'Invalid assignment priority: %. Allowed: low, medium, high, urgent.', p_priority;
  END IF;

  IF length(p_instructions) > 2000 THEN
    RAISE EXCEPTION 'Instructions must not exceed 2000 characters.';
  END IF;

  -- 6. Insert new assignment
  INSERT INTO public.complaint_assignments (
    complaint_id,
    staff_id,
    assigned_by,
    status,
    priority,
    instructions,
    assigned_at
  ) VALUES (
    v_complaint_uuid,
    v_staff_uuid,
    auth.uid(),
    'assigned',
    p_priority,
    p_instructions,
    clock_timestamp()
  ) RETURNING id INTO v_new_assignment_id;

  -- 7. Transition complaint status to inProgress
  UPDATE public.complaints
  SET status = 'inProgress',
      updated_at = clock_timestamp()
  WHERE id = v_complaint_uuid;

  SELECT jsonb_build_object(
    'assignmentId', v_new_assignment_id,
    'complaintId', v_complaint_uuid,
    'staffId', v_staff_uuid,
    'staffName', v_staff.name,
    'status', 'assigned',
    'priority', p_priority,
    'assignedAt', clock_timestamp()
  ) INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.assign_complaint(text, text, text, text) TO authenticated;

-- User Suspension RPC
CREATE OR REPLACE FUNCTION public.suspend_user(user_id text, reason text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_uuid uuid;
BEGIN
  IF NOT public.is_active_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF user_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    v_user_uuid := user_id::uuid;
  ELSE
    SELECT id INTO v_user_uuid FROM auth.users WHERE email = lower(trim(user_id));
    IF v_user_uuid IS NULL THEN
      SELECT id INTO v_user_uuid FROM public.profiles WHERE email = lower(trim(user_id));
    END IF;
  END IF;

  IF v_user_uuid IS NULL THEN
    RAISE EXCEPTION 'User % not found', user_id;
  END IF;

  INSERT INTO public.user_suspensions (user_id, suspended_by, reason, is_active)
  VALUES (v_user_uuid, auth.uid(), reason, true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.suspend_user(text, text) TO authenticated;
