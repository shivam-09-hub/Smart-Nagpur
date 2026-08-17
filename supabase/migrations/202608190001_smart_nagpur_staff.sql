-- =============================================================================
-- Migration: 202608190001_smart_nagpur_staff.sql
-- Description: Staff Database Foundation for Smart Nagpur
--              Introduces Field Staff Profiles, Complaint Assignment History,
--              Field Resolution Evidence, Storage Bucket & Policies, and RLS.
-- Invariants:  Strictly backward-compatible with existing Citizen & Admin schemas.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Table: public.staff_profiles
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.staff_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text NOT NULL DEFAULT '',
  email text NOT NULL UNIQUE,
  employee_id text NOT NULL UNIQUE,
  department text NOT NULL,
  role text NOT NULL DEFAULT 'FIELD_WORKER',
  zone text NOT NULL DEFAULT 'ALL',
  ward text NOT NULL DEFAULT '',
  is_active boolean NOT NULL DEFAULT true,
  is_on_duty boolean NOT NULL DEFAULT false,
  last_active_at timestamptz,
  created_by uuid REFERENCES public.admin_profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),

  CONSTRAINT staff_profiles_name_valid CHECK (
    char_length(btrim(name)) BETWEEN 1 AND 120
  ),
  CONSTRAINT staff_profiles_phone_valid CHECK (
    phone = '' OR phone ~ '^[0-9+() -]{5,32}$'
  ),
  CONSTRAINT staff_profiles_email_valid CHECK (
    char_length(email) BETWEEN 3 AND 320 AND
    email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
  ),
  CONSTRAINT staff_profiles_employee_id_valid CHECK (
    char_length(btrim(employee_id)) BETWEEN 2 AND 40
  ),
  CONSTRAINT staff_profiles_department_valid CHECK (
    department IN ('ROAD', 'WASTE', 'WATER', 'VENDOR', 'GENERAL')
  ),
  CONSTRAINT staff_profiles_role_valid CHECK (
    role IN ('FIELD_WORKER', 'SUPERVISOR', 'OFFICER')
  ),
  CONSTRAINT staff_profiles_zone_valid CHECK (
    char_length(btrim(zone)) BETWEEN 1 AND 80
  ),
  CONSTRAINT staff_profiles_ward_valid CHECK (
    char_length(ward) <= 80
  )
);

-- -----------------------------------------------------------------------------
-- 2. Table: public.complaint_assignments
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.complaint_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  complaint_id uuid NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
  staff_id uuid NOT NULL REFERENCES public.staff_profiles(id) ON DELETE RESTRICT,
  assigned_by uuid NOT NULL REFERENCES public.admin_profiles(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'assigned',
  priority text NOT NULL DEFAULT 'medium',
  instructions text NOT NULL DEFAULT '',
  notes text NOT NULL DEFAULT '',
  rejection_reason text,
  assigned_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  reassigned_to_id uuid REFERENCES public.complaint_assignments(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),

  CONSTRAINT complaint_assignments_status_valid CHECK (
    status IN ('assigned', 'accepted', 'inProgress', 'completed', 'reworkRequired', 'approved', 'reassigned', 'cancelled')
  ),
  CONSTRAINT complaint_assignments_priority_valid CHECK (
    priority IN ('low', 'medium', 'high', 'urgent')
  ),
  CONSTRAINT complaint_assignments_instructions_valid CHECK (
    char_length(instructions) <= 2000
  ),
  CONSTRAINT complaint_assignments_notes_valid CHECK (
    char_length(notes) <= 2000
  ),
  CONSTRAINT complaint_assignments_rejection_valid CHECK (
    rejection_reason IS NULL OR char_length(rejection_reason) <= 1000
  )
);

-- -----------------------------------------------------------------------------
-- 3. Add Safe Optional Assignment Columns to public.complaints
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'complaints' AND column_name = 'current_assignment_id'
  ) THEN
    ALTER TABLE public.complaints
      ADD COLUMN current_assignment_id uuid REFERENCES public.complaint_assignments(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'complaints' AND column_name = 'assigned_department'
  ) THEN
    ALTER TABLE public.complaints
      ADD COLUMN assigned_department text;

    ALTER TABLE public.complaints
      ADD CONSTRAINT complaints_assigned_department_valid CHECK (
        assigned_department IS NULL OR
        assigned_department IN ('ROAD', 'WASTE', 'WATER', 'VENDOR', 'GENERAL')
      );
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 4. Table: public.complaint_evidence
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.complaint_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  complaint_id uuid NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
  assignment_id uuid NOT NULL REFERENCES public.complaint_assignments(id) ON DELETE CASCADE,
  staff_id uuid NOT NULL REFERENCES public.staff_profiles(id) ON DELETE RESTRICT,
  evidence_type text NOT NULL,
  bucket_id text NOT NULL DEFAULT 'complaint-evidence',
  object_path text NOT NULL UNIQUE,
  original_name text NOT NULL,
  content_type text NOT NULL,
  byte_size bigint NOT NULL,
  notes text NOT NULL DEFAULT '',
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  accuracy double precision NOT NULL,
  distance_from_complaint_meters double precision,
  is_geo_verified boolean NOT NULL DEFAULT false,
  captured_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  created_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),

  CONSTRAINT complaint_evidence_type_valid CHECK (
    evidence_type IN ('beforeWork', 'afterWork', 'inspectionReport')
  ),
  CONSTRAINT complaint_evidence_bucket_valid CHECK (
    bucket_id = 'complaint-evidence'
  ),
  CONSTRAINT complaint_evidence_path_valid CHECK (
    char_length(object_path) <= 1024 AND
    object_path NOT LIKE '%//%' AND
    object_path !~ '(^|/)\.{1,2}(/|$)' AND
    position(chr(92) IN object_path) = 0
  ),
  CONSTRAINT complaint_evidence_name_valid CHECK (
    char_length(btrim(original_name)) BETWEEN 1 AND 255
  ),
  CONSTRAINT complaint_evidence_content_type_valid CHECK (
    content_type IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')
  ),
  CONSTRAINT complaint_evidence_size_valid CHECK (
    byte_size BETWEEN 1 AND 10485760
  ),
  CONSTRAINT complaint_evidence_notes_valid CHECK (
    char_length(notes) <= 2000
  ),
  CONSTRAINT complaint_evidence_latitude_valid CHECK (
    latitude BETWEEN -90 AND 90
  ),
  CONSTRAINT complaint_evidence_longitude_valid CHECK (
    longitude BETWEEN -180 AND 180
  ),
  CONSTRAINT complaint_evidence_accuracy_valid CHECK (
    accuracy BETWEEN 0 AND 100000
  )
);

-- -----------------------------------------------------------------------------
-- 5. Safe Indexes Supporting RLS & Lookups
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_staff_profiles_dept_role_active
  ON public.staff_profiles(department, role, is_active);

CREATE INDEX IF NOT EXISTS idx_staff_profiles_duty
  ON public.staff_profiles(is_on_duty, is_active);

CREATE INDEX IF NOT EXISTS idx_complaint_assignments_staff_status
  ON public.complaint_assignments(staff_id, status);

CREATE INDEX IF NOT EXISTS idx_complaint_assignments_complaint
  ON public.complaint_assignments(complaint_id, status);

CREATE INDEX IF NOT EXISTS idx_complaints_current_assignment
  ON public.complaints(current_assignment_id);

CREATE INDEX IF NOT EXISTS idx_complaints_assigned_department
  ON public.complaints(assigned_department, status);

CREATE INDEX IF NOT EXISTS idx_complaint_evidence_complaint_staff
  ON public.complaint_evidence(complaint_id, staff_id);

CREATE INDEX IF NOT EXISTS idx_complaint_evidence_assignment
  ON public.complaint_evidence(assignment_id);

CREATE INDEX IF NOT EXISTS idx_complaint_assignments_status_assigned
  ON public.complaint_assignments(status, assigned_at DESC);

-- -----------------------------------------------------------------------------
-- 6. Helper Security Functions (SECURITY DEFINER, Immutable / Protected)

-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_active_staff()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.staff_profiles
    WHERE id = auth.uid() AND is_active = true
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_staff_department()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_department text;
BEGIN
  SELECT department INTO v_department
  FROM public.staff_profiles
  WHERE id = auth.uid() AND is_active = true;
  RETURN v_department;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_staff_role()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_role text;
BEGIN
  SELECT role INTO v_role
  FROM public.staff_profiles
  WHERE id = auth.uid() AND is_active = true;
  RETURN v_role;
END;
$$;

-- Haversine Distance Calculation (Distance in meters between two GPS coordinates)
CREATE OR REPLACE FUNCTION public.calculate_distance_meters(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
)
RETURNS double precision
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
SET search_path = public, pg_temp
AS $$
DECLARE
  r double precision := 6371000.0; -- Earth radius in meters
  dlat double precision;
  dlon double precision;
  a double precision;
  c double precision;
BEGIN
  IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
    RETURN NULL;
  END IF;

  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);
  a := sin(dlat / 2.0) * sin(dlat / 2.0) +
       cos(radians(lat1)) * cos(radians(lat2)) *
       sin(dlon / 2.0) * sin(dlon / 2.0);
  c := 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
  RETURN r * c;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6.1 Privilege Escalation Prevention Trigger on staff_profiles
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_staff_profile_update_integrity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- If caller is not an active administrator, block modifications to privileged columns
  IF NOT public.is_active_admin() THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Privilege escalation rejected: Staff members cannot change their own role.';
    END IF;

    IF NEW.department IS DISTINCT FROM OLD.department THEN
      RAISE EXCEPTION 'Unauthorized change: Staff members cannot change their own department.';
    END IF;

    IF NEW.employee_id IS DISTINCT FROM OLD.employee_id THEN
      RAISE EXCEPTION 'Unauthorized change: Staff members cannot modify their employee ID.';
    END IF;

    IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
      RAISE EXCEPTION 'Unauthorized change: Staff members cannot modify their active status.';
    END IF;

    IF NEW.created_by IS DISTINCT FROM OLD.created_by THEN
      RAISE EXCEPTION 'Unauthorized change: Staff members cannot modify their creator reference.';
    END IF;

    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.email IS DISTINCT FROM OLD.email THEN
      RAISE EXCEPTION 'Unauthorized change: Staff member primary identity cannot be modified.';
    END IF;
  END IF;

  NEW.updated_at := pg_catalog.clock_timestamp();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_staff_profiles_integrity ON public.staff_profiles;
CREATE TRIGGER trg_staff_profiles_integrity
  BEFORE UPDATE ON public.staff_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.check_staff_profile_update_integrity();


-- -----------------------------------------------------------------------------
-- 6.5 Transactional RPC: assign_complaint
-- -----------------------------------------------------------------------------
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
  -- 1. Authorization: Verify caller is an active Admin
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

  -- 4. Validate Department / Service Type Match
  -- Enforce server-side that the staff department matches the complaint's service type
  IF v_staff.department <> 'GENERAL' THEN
    IF (v_complaint.service_type = 'roads' AND v_staff.department <> 'ROAD') OR
       (v_complaint.service_type IN ('garbage', 'drainage') AND v_staff.department <> 'WASTE') OR
       (v_complaint.service_type = 'water' AND v_staff.department <> 'WATER') OR
       (v_complaint.service_type = 'vendor' AND v_staff.department <> 'VENDOR') THEN
      RAISE EXCEPTION 'Department mismatch: Complaint with service_type "%" cannot be assigned to staff in "%" department.',
        v_complaint.service_type, v_staff.department;
    END IF;
  END IF;

  -- 5. Validate Priority
  IF p_priority NOT IN ('low', 'medium', 'high', 'urgent') THEN
    RAISE EXCEPTION 'Invalid assignment priority: %. Allowed: low, medium, high, urgent.', p_priority;
  END IF;

  -- 6. Validate Instructions Length
  IF length(p_instructions) > 2000 THEN
    RAISE EXCEPTION 'Instructions must not exceed 2000 characters.';
  END IF;

  -- 7. Check existing active assignment
  SELECT id INTO v_prev_assignment_id
  FROM public.complaint_assignments
  WHERE complaint_id = v_complaint_uuid AND status IN ('assigned', 'accepted', 'inProgress')
  ORDER BY created_at DESC
  LIMIT 1;

  -- 8. Insert new assignment
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

  -- 9. If previous active assignment existed, mark it as reassigned
  IF v_prev_assignment_id IS NOT NULL THEN
    UPDATE public.complaint_assignments
    SET status = 'reassigned',
        reassigned_to_id = v_new_assignment_id,
        updated_at = clock_timestamp()
    WHERE id = v_prev_assignment_id;
  END IF;

  -- 9. Update complaint record
  UPDATE public.complaints
  SET current_assignment_id = v_new_assignment_id,
      assigned_department = v_staff.department,
      status = 'assigned',
      updated_at = clock_timestamp()
  WHERE id = p_complaint_id;

  -- 10. Add milestone timeline entry
  INSERT INTO public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    message,
    is_completed
  ) VALUES (
    p_complaint_id,
    v_complaint.owner_id,
    'Complaint Assigned',
    format('Assigned to %s (%s Department) with %s priority. %s',
      v_staff.name,
      v_staff.department,
      p_priority,
      CASE WHEN p_instructions <> '' THEN 'Instructions: ' || p_instructions ELSE '' END
    ),
    true
  );

  -- 11. Return JSON result
  SELECT jsonb_build_object(
    'assignmentId', v_new_assignment_id,
    'complaintId', p_complaint_id,
    'staffId', p_staff_id,
    'staffName', v_staff.name,
    'department', v_staff.department,
    'priority', p_priority,
    'status', 'assigned',
    'assignedAt', clock_timestamp()
  ) INTO v_result;

  RETURN v_result;
END;
$$;


-- -----------------------------------------------------------------------------
-- 6.6 Transactional RPC: accept_complaint_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_complaint_assignment(
  p_assignment_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id uuid := auth.uid();
  v_staff record;
  v_assignment record;
  v_owner_id uuid;
  v_result jsonb;
BEGIN
  -- 1. Authorization: Verify caller is authenticated
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Access denied. Caller is not authenticated.';
  END IF;

  -- 2. Verify caller has an active staff profile
  SELECT * INTO v_staff FROM public.staff_profiles WHERE id = v_caller_id AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Access denied. Caller is not an active staff member.';
  END IF;

  -- 3. Verify assignment exists and belongs to caller
  SELECT * INTO v_assignment FROM public.complaint_assignments WHERE id = p_assignment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Complaint assignment with ID % does not exist.', p_assignment_id;
  END IF;

  IF v_assignment.staff_id <> v_caller_id THEN
    RAISE EXCEPTION 'Access denied. Assignment does not belong to the calling staff member.';
  END IF;

  -- 4. Verify valid previous state
  IF v_assignment.status <> 'assigned' THEN
    RAISE EXCEPTION 'Invalid status transition: Cannot accept assignment in "%" status. Must be "assigned".', v_assignment.status;
  END IF;

  -- 5. Transition to accepted
  UPDATE public.complaint_assignments
  SET status = 'accepted',
      accepted_at = clock_timestamp(),
      updated_at = clock_timestamp()
  WHERE id = p_assignment_id;

  SELECT owner_id INTO v_owner_id FROM public.complaints WHERE id = v_assignment.complaint_id;

  -- 6. Add milestone timeline entry
  INSERT INTO public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    message,
    is_completed
  ) VALUES (
    v_assignment.complaint_id,
    v_owner_id,
    'Task Accepted by Field Staff',
    format('Task accepted by technician %s (%s).', v_staff.name, v_staff.employee_id),
    true
  );

  SELECT jsonb_build_object(
    'assignmentId', p_assignment_id,
    'status', 'accepted',
    'acceptedAt', clock_timestamp()
  ) INTO v_result;

  RETURN v_result;
END;
$$;


-- -----------------------------------------------------------------------------
-- 6.7 Transactional RPC: start_complaint_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_complaint_assignment(
  p_assignment_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id uuid := auth.uid();
  v_staff record;
  v_assignment record;
  v_owner_id uuid;
  v_result jsonb;
BEGIN
  -- 1. Authorization: Verify caller is authenticated
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Access denied. Caller is not authenticated.';
  END IF;

  -- 2. Verify caller has an active staff profile
  SELECT * INTO v_staff FROM public.staff_profiles WHERE id = v_caller_id AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Access denied. Caller is not an active staff member.';
  END IF;

  -- 3. Verify assignment exists and belongs to caller
  SELECT * INTO v_assignment FROM public.complaint_assignments WHERE id = p_assignment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Complaint assignment with ID % does not exist.', p_assignment_id;
  END IF;

  IF v_assignment.staff_id <> v_caller_id THEN
    RAISE EXCEPTION 'Access denied. Assignment does not belong to the calling staff member.';
  END IF;

  -- 4. Verify valid previous state: allowed from 'accepted' or 'reworkRequired'
  IF v_assignment.status NOT IN ('accepted', 'reworkRequired') THEN
    RAISE EXCEPTION 'Invalid status transition: Cannot start work in "%" status. Must be "accepted" or "reworkRequired".', v_assignment.status;
  END IF;

  -- 5. Transition assignment to inProgress
  UPDATE public.complaint_assignments
  SET status = 'inProgress',
      started_at = clock_timestamp(),
      updated_at = clock_timestamp()
  WHERE id = p_assignment_id;

  -- 6. Update complaint status to inProgress
  UPDATE public.complaints
  SET status = 'inProgress',
      updated_at = clock_timestamp()
  WHERE id = v_assignment.complaint_id;

  SELECT owner_id INTO v_owner_id FROM public.complaints WHERE id = v_assignment.complaint_id;

  -- 7. Add milestone timeline entry
  INSERT INTO public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    message,
    is_completed
  ) VALUES (
    v_assignment.complaint_id,
    v_owner_id,
    CASE WHEN v_assignment.status = 'reworkRequired' THEN 'Rework In Progress' ELSE 'Work In Progress' END,
    format('Field technician %s (%s) %s.',
      v_staff.name,
      v_staff.employee_id,
      CASE WHEN v_assignment.status = 'reworkRequired' THEN 'commenced rework actions' ELSE 'commenced field work' END
    ),
    true
  );

  SELECT jsonb_build_object(
    'assignmentId', p_assignment_id,
    'status', 'inProgress',
    'startedAt', clock_timestamp()
  ) INTO v_result;

  RETURN v_result;
END;
$$;


-- -----------------------------------------------------------------------------
-- 6.8 Transactional RPC: complete_complaint_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_complaint_assignment(
  p_assignment_id uuid,
  p_completion_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id uuid := auth.uid();
  v_staff record;
  v_assignment record;
  v_owner_id uuid;
  v_result jsonb;
BEGIN
  -- 1. Authorization: Verify caller is authenticated
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Access denied. Caller is not authenticated.';
  END IF;

  -- 2. Verify caller has an active staff profile
  SELECT * INTO v_staff FROM public.staff_profiles WHERE id = v_caller_id AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Access denied. Caller is not an active staff member.';
  END IF;

  -- 3. Verify assignment exists and belongs to caller
  SELECT * INTO v_assignment FROM public.complaint_assignments WHERE id = p_assignment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Complaint assignment with ID % does not exist.', p_assignment_id;
  END IF;

  IF v_assignment.staff_id <> v_caller_id THEN
    RAISE EXCEPTION 'Access denied. Assignment does not belong to the calling staff member.';
  END IF;

  -- 4. Verify valid previous state
  IF v_assignment.status <> 'inProgress' THEN
    RAISE EXCEPTION 'Invalid status transition: Cannot complete assignment in "%" status. Must be "inProgress".', v_assignment.status;
  END IF;

  -- 5. Validate notes length
  IF length(p_completion_notes) > 2000 THEN
    RAISE EXCEPTION 'Completion notes must not exceed 2000 characters.';
  END IF;

  -- 6. Transition assignment to completed (Awaiting Administrative Verification)
  UPDATE public.complaint_assignments
  SET status = 'completed',
      notes = CASE
        WHEN p_completion_notes <> '' THEN p_completion_notes
        ELSE notes
      END,
      completed_at = clock_timestamp(),
      updated_at = clock_timestamp()
  WHERE id = p_assignment_id;

  -- 7. Update complaint status to underReview (NOT resolved yet; awaiting Admin verification)
  UPDATE public.complaints
  SET status = 'underReview',
      updated_at = clock_timestamp()
  WHERE id = v_assignment.complaint_id;

  SELECT owner_id INTO v_owner_id FROM public.complaints WHERE id = v_assignment.complaint_id;

  -- 8. Add milestone timeline entry
  INSERT INTO public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    message,
    is_completed
  ) VALUES (
    v_assignment.complaint_id,
    v_owner_id,
    'Field Work Submitted',
    format('Field work completed by technician %s (%s) and submitted for verification. %s',
      v_staff.name,
      v_staff.employee_id,
      CASE WHEN p_completion_notes <> '' THEN 'Notes: ' || p_completion_notes ELSE '' END
    ),
    true
  );

  SELECT jsonb_build_object(
    'assignmentId', p_assignment_id,
    'status', 'completed',
    'completedAt', clock_timestamp()
  ) INTO v_result;

  RETURN v_result;
END;
$$;


-- -----------------------------------------------------------------------------
-- 6.9 Transactional RPC: approve_complaint_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.approve_complaint_assignment(
  p_assignment_id uuid,
  p_review_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id uuid := auth.uid();
  v_assignment record;
  v_owner_id uuid;
  v_is_admin boolean := false;
  v_is_supervisor boolean := false;
  v_result jsonb;
BEGIN
  -- 1. Authorization: Verify caller is authenticated
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Access denied. Caller is not authenticated.';
  END IF;

  -- 2. Check Admin or Supervisor status
  v_is_admin := public.is_active_admin();
  IF NOT v_is_admin THEN
    SELECT EXISTS (
      SELECT 1 FROM public.staff_profiles
      WHERE id = v_caller_id AND is_active = true AND role IN ('SUPERVISOR', 'OFFICER')
    ) INTO v_is_supervisor;
  END IF;

  IF NOT (v_is_admin OR v_is_supervisor) THEN
    RAISE EXCEPTION 'Access denied. Caller is not an authorized municipal administrator or supervisor.';
  END IF;

  -- 3. Verify assignment exists
  SELECT * INTO v_assignment FROM public.complaint_assignments WHERE id = p_assignment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Complaint assignment with ID % does not exist.', p_assignment_id;
  END IF;

  -- 3.1 Department isolation for supervisor
  IF NOT v_is_admin THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.complaints c
      WHERE c.id = v_assignment.complaint_id AND c.assigned_department = public.get_staff_department()
    ) THEN
      RAISE EXCEPTION 'Access denied. Supervisor cannot approve tasks outside their department.';
    END IF;
  END IF;

  -- 4. Staff cannot approve their own work
  IF v_assignment.staff_id = v_caller_id THEN
    RAISE EXCEPTION 'Access denied. Staff members cannot approve their own field work.';
  END IF;

  -- 5. Verify valid previous state
  IF v_assignment.status <> 'completed' THEN
    RAISE EXCEPTION 'Invalid status transition: Cannot approve assignment in "%" status. Must be "completed".', v_assignment.status;
  END IF;

  -- 6. Validate review notes length
  IF length(p_review_notes) > 2000 THEN
    RAISE EXCEPTION 'Review notes must not exceed 2000 characters.';
  END IF;

  -- 7. Transition assignment to approved
  UPDATE public.complaint_assignments
  SET status = 'approved',
      updated_at = clock_timestamp()
  WHERE id = p_assignment_id;

  -- 8. Resolve complaint
  UPDATE public.complaints
  SET status = 'resolved',
      updated_at = clock_timestamp()
  WHERE id = v_assignment.complaint_id;

  SELECT owner_id INTO v_owner_id FROM public.complaints WHERE id = v_assignment.complaint_id;

  -- 9. Add milestone timeline entry
  INSERT INTO public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    message,
    is_completed
  ) VALUES (
    v_assignment.complaint_id,
    v_owner_id,
    'Work Approved & Verified',
    format('Field work verified and approved by municipal administration. %s',
      CASE WHEN p_review_notes <> '' THEN 'Reviewer Notes: ' || p_review_notes ELSE '' END
    ),
    true
  );

  SELECT jsonb_build_object(
    'assignmentId', p_assignment_id,
    'status', 'approved',
    'approvedAt', clock_timestamp()
  ) INTO v_result;

  RETURN v_result;
END;
$$;


-- -----------------------------------------------------------------------------
-- 6.10 Transactional RPC: request_rework_complaint_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.request_rework_complaint_assignment(
  p_assignment_id uuid,
  p_rework_instructions text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id uuid := auth.uid();
  v_assignment record;
  v_owner_id uuid;
  v_is_admin boolean := false;
  v_is_supervisor boolean := false;
  v_result jsonb;
BEGIN
  -- 1. Authorization: Verify caller is authenticated
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Access denied. Caller is not authenticated.';
  END IF;

  -- 2. Check Admin or Supervisor status
  v_is_admin := public.is_active_admin();
  IF NOT v_is_admin THEN
    SELECT EXISTS (
      SELECT 1 FROM public.staff_profiles
      WHERE id = v_caller_id AND is_active = true AND role IN ('SUPERVISOR', 'OFFICER')
    ) INTO v_is_supervisor;
  END IF;

  IF NOT (v_is_admin OR v_is_supervisor) THEN
    RAISE EXCEPTION 'Access denied. Caller is not an authorized municipal administrator or supervisor.';
  END IF;

  -- 3. Verify assignment exists
  SELECT * INTO v_assignment FROM public.complaint_assignments WHERE id = p_assignment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Complaint assignment with ID % does not exist.', p_assignment_id;
  END IF;

  -- 3.1 Department isolation for supervisor
  IF NOT v_is_admin THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.complaints c
      WHERE c.id = v_assignment.complaint_id AND c.assigned_department = public.get_staff_department()
    ) THEN
      RAISE EXCEPTION 'Access denied. Supervisor cannot request rework on tasks outside their department.';
    END IF;
  END IF;

  -- 4. Staff cannot reject/rework their own work
  IF v_assignment.staff_id = v_caller_id THEN
    RAISE EXCEPTION 'Access denied. Staff members cannot review their own field work.';
  END IF;

  -- 5. Verify valid previous state
  IF v_assignment.status <> 'completed' THEN
    RAISE EXCEPTION 'Invalid status transition: Cannot request rework on assignment in "%" status. Must be "completed".', v_assignment.status;
  END IF;

  -- 6. Validate instructions length
  IF length(p_rework_instructions) > 1000 THEN
    RAISE EXCEPTION 'Rework instructions must not exceed 1000 characters.';
  END IF;

  -- 7. Transition assignment to reworkRequired
  UPDATE public.complaint_assignments
  SET status = 'reworkRequired',
      rejection_reason = p_rework_instructions,
      updated_at = clock_timestamp()
  WHERE id = p_assignment_id;

  -- 8. Update complaint status to inProgress
  UPDATE public.complaints
  SET status = 'inProgress',
      updated_at = clock_timestamp()
  WHERE id = v_assignment.complaint_id;

  SELECT owner_id INTO v_owner_id FROM public.complaints WHERE id = v_assignment.complaint_id;

  -- 9. Add milestone timeline entry
  INSERT INTO public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    message,
    is_completed
  ) VALUES (
    v_assignment.complaint_id,
    v_owner_id,
    'Rework Requested',
    format('Administrative review requested field rework. %s',
      CASE WHEN p_rework_instructions <> '' THEN 'Instructions: ' || p_rework_instructions ELSE 'Standard corrective measures required.' END
    ),
    true
  );


  SELECT jsonb_build_object(
    'assignmentId', p_assignment_id,
    'status', 'reworkRequired',
    'reworkRequestedAt', clock_timestamp()
  ) INTO v_result;

  RETURN v_result;
END;
$$;


-- -----------------------------------------------------------------------------
-- 6.11 Transactional RPC: record_complaint_evidence
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_complaint_evidence(
  p_assignment_id uuid,
  p_evidence_type text,
  p_object_path text,
  p_original_name text,
  p_content_type text,
  p_byte_size bigint,
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy double precision,
  p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id uuid := auth.uid();
  v_staff record;
  v_assignment record;
  v_complaint record;
  v_distance double precision := NULL;
  v_is_geo_verified boolean := false;
  v_evidence_id uuid;
  v_expected_path_prefix text;
  v_filename_part text;
  v_result jsonb;
BEGIN
  -- 1. Authorization: Verify caller is authenticated
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Access denied. Caller is not authenticated.';
  END IF;

  -- 2. Verify caller has an active staff profile
  SELECT * INTO v_staff FROM public.staff_profiles WHERE id = v_caller_id AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Access denied. Caller is not an active staff member.';
  END IF;

  -- 3. Verify assignment exists and belongs to caller
  SELECT * INTO v_assignment FROM public.complaint_assignments WHERE id = p_assignment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Complaint assignment with ID % does not exist.', p_assignment_id;
  END IF;

  IF v_assignment.staff_id <> v_caller_id THEN
    RAISE EXCEPTION 'Access denied. Staff member cannot upload evidence to another staff assignment.';
  END IF;

  -- 4. Verify assignment is in an active working state:
  IF v_assignment.status IN ('approved', 'cancelled', 'reassigned') THEN
    RAISE EXCEPTION 'Invalid state: Evidence cannot be added to assignment in "%" status.', v_assignment.status;
  END IF;

  IF v_assignment.status = 'completed' THEN
    RAISE EXCEPTION 'Invalid state: Assignment is completed and awaiting review. Additional evidence cannot be attached unless rework is requested.';
  END IF;

  -- 5. Validate Evidence Type
  IF p_evidence_type NOT IN ('beforeWork', 'afterWork', 'inspectionReport') THEN
    RAISE EXCEPTION 'Invalid evidence type: %. Must be beforeWork, afterWork, or inspectionReport.', p_evidence_type;
  END IF;

  -- 5.1 Evidence type lifecycle constraints:
  -- After-work evidence can only be submitted after work has started
  IF p_evidence_type = 'afterWork' AND v_assignment.status NOT IN ('inProgress', 'reworkRequired') THEN
    RAISE EXCEPTION 'Invalid lifecycle state: After-work evidence can only be submitted when work is inProgress or reworkRequired.';
  END IF;

  -- 5.2 Prevent duplicate evidence of same type for the same assignment unless under rework
  IF v_assignment.status <> 'reworkRequired' AND EXISTS (
    SELECT 1 FROM public.complaint_evidence
    WHERE assignment_id = p_assignment_id AND evidence_type = p_evidence_type
  ) THEN
    RAISE EXCEPTION 'Evidence of type "%" has already been submitted for this assignment.', p_evidence_type;
  END IF;

  -- 6. Validate Content Type and Size
  IF p_content_type NOT IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf') THEN
    RAISE EXCEPTION 'Invalid content type: %. Allowed: image/jpeg, image/png, image/webp, application/pdf.', p_content_type;
  END IF;

  -- Photos must not be PDFs
  IF p_evidence_type IN ('beforeWork', 'afterWork') AND p_content_type = 'application/pdf' THEN
    RAISE EXCEPTION 'Invalid content type: Photographic evidence cannot be a PDF document.';
  END IF;

  IF p_byte_size <= 0 OR p_byte_size > 10485760 THEN
    RAISE EXCEPTION 'Invalid file size: % bytes. Must be between 1 byte and 10MB.', p_byte_size;
  END IF;

  -- 6.1 Validate Original Name length
  IF p_original_name IS NULL OR length(btrim(p_original_name)) < 1 OR length(p_original_name) > 255 THEN
    RAISE EXCEPTION 'Invalid original file name.';
  END IF;

  -- 7. Validate Storage Path Security (<staff_id>/<complaint_id>/<assignment_id>/<filename>)
  v_expected_path_prefix := v_caller_id::text || '/' || v_assignment.complaint_id::text || '/' || p_assignment_id::text || '/';
  
  IF NOT (p_object_path LIKE (v_expected_path_prefix || '%')) THEN
    RAISE EXCEPTION 'Invalid storage path: Object path does not match expected prefix structure.';
  END IF;

  -- Reject directory traversal, backslashes, double slashes
  IF p_object_path LIKE '%//%' OR
     p_object_path ~ '(^|/)\.{1,2}(/|$)' OR
     position(chr(92) IN p_object_path) > 0 THEN
    RAISE EXCEPTION 'Path traversal or malformed characters detected in object path.';
  END IF;

  -- Check filename component
  v_filename_part := substring(p_object_path from length(v_expected_path_prefix) + 1);
  IF v_filename_part ~ '/' OR length(v_filename_part) < 3 OR length(v_filename_part) > 200 THEN
    RAISE EXCEPTION 'Malformed filename component in object path.';
  END IF;

  -- 8. Validate GPS Coordinates & Range
  IF p_latitude < -90.0 OR p_latitude > 90.0 THEN
    RAISE EXCEPTION 'Invalid latitude value: % (Must be between -90 and 90).', p_latitude;
  END IF;

  IF p_longitude < -180.0 OR p_longitude > 180.0 THEN
    RAISE EXCEPTION 'Invalid longitude value: % (Must be between -180 and 180).', p_longitude;
  END IF;

  IF p_accuracy < 0.0 OR p_accuracy > 1000.0 THEN
    RAISE EXCEPTION 'Invalid GPS accuracy: % meters (Must be between 0 and 1000).', p_accuracy;
  END IF;

  -- Fetch complaint coordinates and compute authoritative server-side distance
  SELECT * INTO v_complaint FROM public.complaints WHERE id = v_assignment.complaint_id;

  IF v_complaint.latitude IS NOT NULL AND v_complaint.longitude IS NOT NULL THEN
    v_distance := public.calculate_distance_meters(
      p_latitude,
      p_longitude,
      v_complaint.latitude,
      v_complaint.longitude
    );

    -- Server-side authoritative geo verification: Distance <= 100m AND Accuracy <= 50m
    IF v_distance IS NOT NULL AND v_distance <= 100.0 AND p_accuracy <= 50.0 THEN
      v_is_geo_verified := true;
    END IF;
  END IF;

  -- 9. Insert Evidence Record (Atomic)
  INSERT INTO public.complaint_evidence (
    complaint_id,
    assignment_id,
    staff_id,
    evidence_type,
    bucket_id,
    object_path,
    original_name,
    content_type,
    byte_size,
    notes,
    latitude,
    longitude,
    accuracy,
    distance_from_complaint_meters,
    is_geo_verified,
    captured_at
  ) VALUES (
    v_assignment.complaint_id,
    p_assignment_id,
    v_caller_id,
    p_evidence_type,
    'complaint-evidence',
    p_object_path,
    p_original_name,
    p_content_type,
    p_byte_size,
    COALESCE(p_notes, ''),
    p_latitude,
    p_longitude,
    p_accuracy,
    v_distance,
    v_is_geo_verified,
    clock_timestamp()
  ) RETURNING id INTO v_evidence_id;

  -- 10. Add milestone timeline entry
  INSERT INTO public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    message,
    is_completed
  ) VALUES (
    v_assignment.complaint_id,
    v_complaint.owner_id,
    CASE
      WHEN p_evidence_type = 'beforeWork' THEN 'Before-Work Photo Uploaded'
      WHEN p_evidence_type = 'afterWork' THEN 'After-Work Photo Uploaded'
      ELSE 'Inspection Report Uploaded'
    END,
    format('%s uploaded by %s (%s). GPS %s (Distance: %sm, Accuracy: %sm).',
      CASE
        WHEN p_evidence_type = 'beforeWork' THEN 'Before-work photographic proof'
        WHEN p_evidence_type = 'afterWork' THEN 'After-work photographic proof'
        ELSE 'Inspection report PDF'
      END,
      v_staff.name,
      v_staff.employee_id,
      CASE WHEN v_is_geo_verified THEN 'Verified' ELSE 'Unverified/Outside Radius' END,
      COALESCE(round(v_distance::numeric, 1)::text, 'N/A'),
      COALESCE(round(p_accuracy::numeric, 1)::text, 'N/A')
    ),
    true
  );

  SELECT jsonb_build_object(
    'evidenceId', v_evidence_id,
    'assignmentId', p_assignment_id,
    'complaintId', v_assignment.complaint_id,
    'evidenceType', p_evidence_type,
    'distanceFromComplaintMeters', v_distance,
    'isGeoVerified', v_is_geo_verified,
    'capturedAt', clock_timestamp()
  ) INTO v_result;

  RETURN v_result;
END;
$$;





-- -----------------------------------------------------------------------------
-- 7. Timestamp & Profile Safety Triggers
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_staff_profiles_updated_at'
  ) THEN
    CREATE TRIGGER trg_staff_profiles_updated_at
      BEFORE UPDATE ON public.staff_profiles
      FOR EACH ROW
      EXECUTE FUNCTION public.set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_complaint_assignments_updated_at'
  ) THEN
    CREATE TRIGGER trg_complaint_assignments_updated_at
      BEFORE UPDATE ON public.complaint_assignments
      FOR EACH ROW
      EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- Safety Trigger: Prevent Staff from updating role, department, employee_id, or is_active
CREATE OR REPLACE FUNCTION public.enforce_staff_profile_update_safety()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- If executed in direct SQL / seed context (auth.uid() IS NULL) or by an active Admin, permit administrative modifications
  IF auth.uid() IS NULL OR public.is_active_admin() OR current_user IN ('postgres', 'supabase_admin') THEN
    RETURN NEW;
  END IF;

  -- Staff members can ONLY update their own on_duty status and last_active_at timestamp
  IF auth.uid() = OLD.id THEN
    IF NEW.role <> OLD.role OR
       NEW.department <> OLD.department OR
       NEW.employee_id <> OLD.employee_id OR
       NEW.is_active <> OLD.is_active OR
       NEW.created_by IS DISTINCT FROM OLD.created_by OR
       NEW.created_at <> OLD.created_at THEN
      RAISE EXCEPTION 'Unauthorized modification of protected staff profile attributes.';
    END IF;
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Access denied to update staff profile.';
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_staff_profile_safety'
  ) THEN
    CREATE TRIGGER trg_staff_profile_safety
      BEFORE UPDATE ON public.staff_profiles
      FOR EACH ROW
      EXECUTE FUNCTION public.enforce_staff_profile_update_safety();
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 8. Row-Level Security (RLS) Policies & Recursion-Free Helpers
-- -----------------------------------------------------------------------------
ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_evidence ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.staff_profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_assignments FORCE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_evidence FORCE ROW LEVEL SECURITY;

-- 8.0 Security Definer Cross-Table Helpers (Prevents Infinite RLS Recursion)
CREATE OR REPLACE FUNCTION public.is_complaint_assigned_to_staff(p_complaint_id uuid, p_staff_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE complaint_id = p_complaint_id AND staff_id = p_staff_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_complaint_owner(p_complaint_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.complaints
    WHERE id = p_complaint_id AND owner_id = p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_complaint_in_staff_department(p_complaint_id uuid, p_department text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.complaints
    WHERE id = p_complaint_id AND assigned_department = p_department
  );
$$;

CREATE OR REPLACE FUNCTION public.is_assignment_active_for_staff(p_assignment_id uuid, p_complaint_id uuid, p_staff_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE id = p_assignment_id AND
          complaint_id = p_complaint_id AND
          staff_id = p_staff_id AND
          status IN ('accepted', 'inProgress', 'reworkRequired')
  );
$$;

-- 8.1 staff_profiles Policies
DROP POLICY IF EXISTS staff_profiles_select_self ON public.staff_profiles;
CREATE POLICY staff_profiles_select_self ON public.staff_profiles
  FOR SELECT USING (
    auth.uid() = id OR
    public.is_active_admin() OR
    (
      public.is_active_staff() AND
      public.get_staff_role() IN ('SUPERVISOR', 'OFFICER') AND
      department = public.get_staff_department()
    )
  );

DROP POLICY IF EXISTS staff_profiles_update_self ON public.staff_profiles;
CREATE POLICY staff_profiles_update_self ON public.staff_profiles
  FOR UPDATE USING (
    auth.uid() = id OR public.is_active_admin()
  );

DROP POLICY IF EXISTS staff_profiles_admin_all ON public.staff_profiles;
CREATE POLICY staff_profiles_admin_all ON public.staff_profiles
  FOR ALL USING (public.is_active_admin());

-- 8.2 complaint_assignments Policies
DROP POLICY IF EXISTS complaint_assignments_select ON public.complaint_assignments;
CREATE POLICY complaint_assignments_select ON public.complaint_assignments
  FOR SELECT USING (
    staff_id = auth.uid() OR
    public.is_active_admin() OR
    (
      public.is_active_staff() AND
      public.get_staff_role() IN ('SUPERVISOR', 'OFFICER') AND
      public.is_complaint_in_staff_department(complaint_id, public.get_staff_department())
    )
  );

DROP POLICY IF EXISTS complaint_assignments_update_staff ON public.complaint_assignments;
CREATE POLICY complaint_assignments_update_staff ON public.complaint_assignments
  FOR UPDATE USING (
    staff_id = auth.uid() AND public.is_active_staff()
  );

DROP POLICY IF EXISTS complaint_assignments_admin_all ON public.complaint_assignments;
CREATE POLICY complaint_assignments_admin_all ON public.complaint_assignments
  FOR ALL USING (public.is_active_admin());

-- 8.3 Staff Access on public.complaints (Add Staff Policy Without Affecting Citizens or Admins)
DROP POLICY IF EXISTS complaints_staff_select ON public.complaints;
CREATE POLICY complaints_staff_select ON public.complaints
  FOR SELECT USING (
    public.is_active_staff() AND (
      public.is_complaint_assigned_to_staff(id, auth.uid()) OR
      (
        public.get_staff_role() IN ('SUPERVISOR', 'OFFICER') AND
        assigned_department = public.get_staff_department()
      )
    )
  );

-- 8.4 complaint_evidence Policies
DROP POLICY IF EXISTS complaint_evidence_insert ON public.complaint_evidence;
CREATE POLICY complaint_evidence_insert ON public.complaint_evidence
  FOR INSERT WITH CHECK (
    public.is_active_staff() AND
    staff_id = auth.uid() AND
    public.is_assignment_active_for_staff(assignment_id, complaint_id, auth.uid())
  );

DROP POLICY IF EXISTS complaint_evidence_select ON public.complaint_evidence;
CREATE POLICY complaint_evidence_select ON public.complaint_evidence
  FOR SELECT USING (
    public.is_active_admin() OR
    (public.is_active_staff() AND (
      staff_id = auth.uid() OR
      public.get_staff_role() IN ('SUPERVISOR', 'OFFICER')
    )) OR
    public.is_complaint_owner(complaint_id, auth.uid())
  );

DROP POLICY IF EXISTS complaint_evidence_update ON public.complaint_evidence;
CREATE POLICY complaint_evidence_update ON public.complaint_evidence
  FOR UPDATE USING (public.is_active_admin());

DROP POLICY IF EXISTS complaint_evidence_delete ON public.complaint_evidence;
CREATE POLICY complaint_evidence_delete ON public.complaint_evidence
  FOR DELETE USING (public.is_active_admin());

-- -----------------------------------------------------------------------------
-- 9. Private Storage Bucket & Storage RLS Policies: 'complaint-evidence'
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'complaint-evidence',
  'complaint-evidence',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

DROP POLICY IF EXISTS staff_evidence_upload ON storage.objects;
CREATE POLICY staff_evidence_upload ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'complaint-evidence' AND
    public.is_active_staff() AND
    split_part(name, '/', 1) = auth.uid()::text AND
    name !~ '(^|/)\.{1,2}(/|$)' AND
    name NOT LIKE '%//%' AND
    position(chr(92) IN name) = 0 AND
    EXISTS (
      SELECT 1 FROM public.complaint_assignments ca
      WHERE ca.id::text = split_part(name, '/', 3) AND
            ca.complaint_id::text = split_part(name, '/', 2) AND
            ca.staff_id = auth.uid() AND
            ca.status IN ('accepted', 'inProgress', 'reworkRequired')
    )
  );

DROP POLICY IF EXISTS staff_evidence_select ON storage.objects;
CREATE POLICY staff_evidence_select ON storage.objects
  FOR SELECT USING (
    bucket_id = 'complaint-evidence' AND (
      public.is_active_admin() OR
      (public.is_active_staff() AND (
        split_part(name, '/', 1) = auth.uid()::text OR
        public.get_staff_role() IN ('SUPERVISOR', 'OFFICER')
      )) OR
      (
        EXISTS (
          SELECT 1 FROM public.complaints c
          WHERE c.id::text = split_part(name, '/', 2) AND c.owner_id = auth.uid()
        )
      )
    )
  );

DROP POLICY IF EXISTS staff_evidence_update ON storage.objects;
CREATE POLICY staff_evidence_update ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'complaint-evidence' AND public.is_active_admin()
  );

DROP POLICY IF EXISTS staff_evidence_delete ON storage.objects;
CREATE POLICY staff_evidence_delete ON storage.objects
  FOR DELETE USING (
    bucket_id = 'complaint-evidence' AND public.is_active_admin()
  );

-- -----------------------------------------------------------------------------
-- 10. Operations & Verification Dashboard RPC (Step 10)
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_complaint_assignments_completed_priority
  ON public.complaint_assignments(status, priority, completed_at);

CREATE INDEX IF NOT EXISTS idx_complaints_status_created
  ON public.complaints(status, created_at);

CREATE OR REPLACE FUNCTION public.get_admin_operations_dashboard(
  p_department text DEFAULT NULL,
  p_priority text DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_staff_id uuid DEFAULT NULL,
  p_from_date timestamptz DEFAULT NULL,
  p_to_date timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id uuid := auth.uid();
  v_is_admin boolean;
  v_is_supervisor boolean;
  v_caller_dept text;
  v_effective_dept text;
  v_result jsonb;

  v_complaints_by_status jsonb;
  v_assignments_by_status jsonb;
  v_staff_summary jsonb;
  v_staff_workloads jsonb;
  v_verification_queue jsonb;
BEGIN
  -- 1. Authorization: Verify caller is active Admin or Department Supervisor/Officer
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  v_is_admin := public.is_active_admin();
  
  SELECT (role IN ('SUPERVISOR', 'OFFICER')), department
  INTO v_is_supervisor, v_caller_dept
  FROM public.staff_profiles
  WHERE id = v_caller_id AND is_active = true;

  IF NOT (v_is_admin OR coalesce(v_is_supervisor, false)) THEN
    RAISE EXCEPTION 'Access denied. Administrator or Supervisor credentials required.';
  END IF;

  -- 2. Department Scoping: Supervisors can only view their own department
  IF v_is_admin THEN
    v_effective_dept := NULLIF(btrim(p_department), '');
  ELSE
    v_effective_dept := v_caller_dept;
  END IF;

  -- 3. Aggregate Complaints by Status
  SELECT jsonb_object_agg(status, count)
  INTO v_complaints_by_status
  FROM (
    SELECT c.status, COUNT(*)::int as count
    FROM public.complaints c
    WHERE (v_effective_dept IS NULL OR c.service_type ILIKE v_effective_dept || '%' OR c.assigned_department = v_effective_dept)
      AND (p_from_date IS NULL OR c.created_at >= p_from_date)
      AND (p_to_date IS NULL OR c.created_at <= p_to_date)
    GROUP BY c.status
  ) s;

  -- 4. Aggregate Assignments by Status
  SELECT jsonb_object_agg(status, count)
  INTO v_assignments_by_status
  FROM (
    SELECT ca.status, COUNT(*)::int as count
    FROM public.complaint_assignments ca
    JOIN public.staff_profiles sp ON sp.id = ca.staff_id
    WHERE (v_effective_dept IS NULL OR sp.department = v_effective_dept)
      AND (p_priority IS NULL OR ca.priority = p_priority)
      AND (p_staff_id IS NULL OR ca.staff_id = p_staff_id)
      AND (p_from_date IS NULL OR ca.assigned_at >= p_from_date)
      AND (p_to_date IS NULL OR ca.assigned_at <= p_to_date)
    GROUP BY ca.status
  ) a;

  -- 5. Staff Workload Summary
  SELECT jsonb_build_object(
    'total_staff', COUNT(DISTINCT sp.id)::int,
    'active_staff', COUNT(DISTINCT CASE WHEN sp.is_active THEN sp.id END)::int,
    'on_duty_staff', COUNT(DISTINCT CASE WHEN sp.is_active AND sp.is_on_duty THEN sp.id END)::int,
    'pending_tasks', COUNT(CASE WHEN ca.status IN ('assigned', 'accepted') THEN 1 END)::int,
    'in_progress_tasks', COUNT(CASE WHEN ca.status IN ('inProgress', 'reworkRequired') THEN 1 END)::int,
    'completed_tasks', COUNT(CASE WHEN ca.status IN ('completed', 'approved') THEN 1 END)::int
  )
  INTO v_staff_summary
  FROM public.staff_profiles sp
  LEFT JOIN public.complaint_assignments ca ON ca.staff_id = sp.id
  WHERE (v_effective_dept IS NULL OR sp.department = v_effective_dept);

  -- 6. Staff Workloads List
  SELECT coalesce(jsonb_agg(sw), '[]'::jsonb)
  INTO v_staff_workloads
  FROM (
    SELECT 
      sp.id AS staff_id,
      sp.name,
      sp.employee_id,
      sp.department,
      sp.role,
      sp.is_on_duty,
      sp.is_active,
      sp.last_active_at,
      COUNT(CASE WHEN ca.status IN ('assigned', 'accepted', 'inProgress', 'reworkRequired') THEN 1 END)::int AS active_task_count,
      COUNT(CASE WHEN ca.status IN ('completed', 'approved') THEN 1 END)::int AS completed_task_count
    FROM public.staff_profiles sp
    LEFT JOIN public.complaint_assignments ca ON ca.staff_id = sp.id
    WHERE (v_effective_dept IS NULL OR sp.department = v_effective_dept)
      AND (p_staff_id IS NULL OR sp.id = p_staff_id)
      AND sp.is_active = true
    GROUP BY sp.id, sp.name, sp.employee_id, sp.department, sp.role, sp.is_on_duty, sp.is_active, sp.last_active_at
    ORDER BY sp.is_on_duty DESC, active_task_count DESC, sp.name ASC
  ) sw;

  -- 7. Verification Queue (Assignments in completed state requiring admin verification)
  SELECT coalesce(jsonb_agg(vq), '[]'::jsonb)
  INTO v_verification_queue
  FROM (
    SELECT 
      c.id AS complaint_id,
      ca.id AS assignment_id,
      c.issue AS issue,
      c.service_type,
      ca.priority,
      c.location_address AS complaint_address,
      c.created_at AS complaint_created_at,
      sp.id AS staff_id,
      sp.name AS staff_name,
      sp.employee_id AS staff_employee_id,
      ca.assigned_at,
      ca.completed_at,
      EXTRACT(EPOCH FROM (now() - ca.completed_at))/3600.0 AS assignment_age_hours,
      ca.notes AS technician_notes,
      coalesce(ev_summary.evidence_count, 0)::int AS evidence_count,
      coalesce(ev_summary.has_before_photo, false) AS has_before_photo,
      coalesce(ev_summary.has_after_photo, false) AS has_after_photo,
      coalesce(ev_summary.has_inspection_pdf, false) AS has_inspection_pdf,
      coalesce(ev_summary.is_geo_verified, false) AS is_geo_verified,
      ev_summary.distance_meters,
      ev_summary.accuracy_meters
    FROM public.complaint_assignments ca
    JOIN public.complaints c ON c.id = ca.complaint_id
    JOIN public.staff_profiles sp ON sp.id = ca.staff_id
    LEFT JOIN LATERAL (
      SELECT 
        COUNT(*)::int AS evidence_count,
        bool_or(evidence_type = 'beforeWork') AS has_before_photo,
        bool_or(evidence_type = 'afterWork') AS has_after_photo,
        bool_or(evidence_type = 'inspectionReport') AS has_inspection_pdf,
        bool_or(is_geo_verified) AS is_geo_verified,
        MIN(distance_from_complaint_meters) AS distance_meters,
        MIN(accuracy) AS accuracy_meters
      FROM public.complaint_evidence ce
      WHERE ce.assignment_id = ca.id
    ) ev_summary ON true
    WHERE ca.status = 'completed'
      AND (v_effective_dept IS NULL OR sp.department = v_effective_dept)
      AND (p_priority IS NULL OR ca.priority = p_priority)
      AND (p_staff_id IS NULL OR ca.staff_id = p_staff_id)
      AND (p_from_date IS NULL OR ca.completed_at >= p_from_date)
      AND (p_to_date IS NULL OR ca.completed_at <= p_to_date)
    ORDER BY 
      CASE ca.priority 
        WHEN 'urgent' THEN 0 
        WHEN 'high' THEN 1 
        WHEN 'medium' THEN 2 
        ELSE 3 
      END ASC,
      ca.completed_at ASC
  ) vq;

  -- 8. Assemble Final JSON Result
  v_result := jsonb_build_object(
    'complaints_by_status', coalesce(v_complaints_by_status, '{}'::jsonb),
    'assignments_by_status', coalesce(v_assignments_by_status, '{}'::jsonb),
    'staff_workload_summary', coalesce(v_staff_summary, '{}'::jsonb),
    'staff_workloads', v_staff_workloads,
    'verification_queue', v_verification_queue
  );

  RETURN v_result;
END;
$$;

-- -----------------------------------------------------------------------------
-- 11. Security Definer Permissions & Grants
-- -----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.is_active_staff() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_active_staff() TO authenticated;

REVOKE ALL ON FUNCTION public.get_staff_department() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_staff_department() TO authenticated;

REVOKE ALL ON FUNCTION public.get_staff_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_staff_role() TO authenticated;

REVOKE ALL ON FUNCTION public.calculate_distance_meters(double precision, double precision, double precision, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.calculate_distance_meters(double precision, double precision, double precision, double precision) TO authenticated;

REVOKE ALL ON FUNCTION public.assign_complaint(text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_complaint(text, text, text, text) TO authenticated;

REVOKE ALL ON FUNCTION public.accept_complaint_assignment(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_complaint_assignment(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.start_complaint_assignment(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.start_complaint_assignment(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.complete_complaint_assignment(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_complaint_assignment(uuid, text) TO authenticated;

REVOKE ALL ON FUNCTION public.approve_complaint_assignment(uuid, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.approve_complaint_assignment(uuid, text) TO authenticated;

REVOKE ALL ON FUNCTION public.request_rework_complaint_assignment(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_rework_complaint_assignment(uuid, text) TO authenticated;

REVOKE ALL ON FUNCTION public.record_complaint_evidence(uuid, text, text, text, text, bigint, double precision, double precision, double precision, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_complaint_evidence(uuid, text, text, text, text, bigint, double precision, double precision, double precision, text) TO authenticated;

-- 10.9 Admin RPC to Provision Staff Account (Auth User + Profile + Staff Profile)
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

  -- 4. Check / Upsert auth.users
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
      raw_app_meta_data,
      raw_user_meta_data,
      is_sso_user,
      is_anonymous,
      created_at,
      updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_new_user_id,
      'authenticated',
      'authenticated',
      v_norm_email,
      v_encrypted_pw,
      now(),
      '{"provider": "email", "providers": ["email"]}'::jsonb,
      jsonb_build_object('name', p_name, 'role', p_role, 'department', p_department),
      false,
      false,
      now(),
      now()
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = v_encrypted_pw,
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        raw_app_meta_data = '{"provider": "email", "providers": ["email"]}'::jsonb,
        raw_user_meta_data = jsonb_build_object('name', p_name, 'role', p_role, 'department', p_department),
        is_sso_user = false,
        updated_at = now()
    WHERE id = v_new_user_id;
  END IF;

  -- 5. Ensure identity exists in auth.identities
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
    now(),
    now(),
    now()
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
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      email = EXCLUDED.email,
      phone = EXCLUDED.phone,
      updated_at = now();

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
    now(),
    now()
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

REVOKE ALL ON FUNCTION public.get_admin_operations_dashboard(text, text, text, uuid, timestamptz, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_operations_dashboard(text, text, text, uuid, timestamptz, timestamptz) TO authenticated;

-- Revoke default table access from public and anon
REVOKE ALL ON TABLE
  public.staff_profiles,
  public.complaint_assignments,
  public.complaint_evidence
FROM public, anon, authenticated;


-- Grant SELECT to authenticated users (row-level filtering is strictly enforced by RLS)
GRANT SELECT ON TABLE
  public.staff_profiles,
  public.complaint_assignments,
  public.complaint_evidence
TO authenticated;

-- Grant restricted column-level UPDATE on staff_profiles for authenticated users
GRANT UPDATE (phone, is_on_duty, last_active_at)
ON public.staff_profiles TO authenticated;

-- -----------------------------------------------------------------------------
-- 12. Realtime Subscription Enrollment

-- -----------------------------------------------------------------------------
-- Enable Realtime replication for complaint_assignments so field staff receive instant task alerts
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'complaint_assignments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_assignments;
  END IF;
END $$;

