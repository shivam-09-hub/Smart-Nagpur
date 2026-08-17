-- =============================================================================
-- Test Suite: 202608190001_smart_nagpur_staff_test.sql
-- Description: Verifies the Staff Database Foundation, RLS, Haversine Distance,
--              Field Constraints, Security Definer Functions, and Schema Integrity.
-- Execution: Runs within a transaction and rolls back cleanly to avoid altering state.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_missing_tables text;
  v_missing_columns text;
  v_insecure_functions text;
  v_calc_dist double precision;
  v_test_complaint_id uuid := gen_random_uuid();
  v_test_user_id uuid := gen_random_uuid();
  v_road_staff_id uuid := gen_random_uuid();
  v_waste_staff_id uuid := gen_random_uuid();
  v_water_staff_id uuid := gen_random_uuid();
  v_vendor_staff_id uuid := gen_random_uuid();
  v_admin_id uuid := gen_random_uuid();
  v_citizen_id uuid := gen_random_uuid();
  v_staff_1_id uuid := gen_random_uuid();
  v_staff_2_id uuid := gen_random_uuid();
  v_other_citizen_id uuid := gen_random_uuid();
  v_error_caught boolean := false;
  v_err_msg text;
  v_assigned_result jsonb;
  v_task_assignment_id uuid;
  v_ev_complaint_id uuid := gen_random_uuid();
  v_ev_assignment_id uuid;
  v_ev_result jsonb;
  v_ev_evidence_id uuid;
  v_dashboard jsonb;
  v_index_count int;
BEGIN
  -- ---------------------------------------------------------------------------
  -- 1. Verify New Tables Exist
  -- ---------------------------------------------------------------------------
  SELECT string_agg(expected.table_name, ', ' ORDER BY expected.table_name)
  INTO v_missing_tables
  FROM unnest(ARRAY[
    'staff_profiles',
    'complaint_assignments',
    'complaint_evidence'
  ]) AS expected(table_name)
  WHERE to_regclass('public.' || expected.table_name) IS NULL;

  IF v_missing_tables IS NOT NULL THEN
    RAISE EXCEPTION 'Missing expected staff tables: %', v_missing_tables;
  END IF;

  -- ---------------------------------------------------------------------------
  -- 2. Verify Columns & Structural Integrity
  -- ---------------------------------------------------------------------------
  SELECT string_agg(
    expected.table_name || '.' || expected.column_name,
    ', ' ORDER BY expected.table_name, expected.column_name
  )
  INTO v_missing_columns
  FROM (
    VALUES
      ('staff_profiles', 'id'),
      ('staff_profiles', 'name'),
      ('staff_profiles', 'phone'),
      ('staff_profiles', 'email'),
      ('staff_profiles', 'employee_id'),
      ('staff_profiles', 'department'),
      ('staff_profiles', 'role'),
      ('staff_profiles', 'zone'),
      ('staff_profiles', 'is_active'),
      ('staff_profiles', 'is_on_duty'),
      ('complaint_assignments', 'complaint_id'),
      ('complaint_assignments', 'staff_id'),
      ('complaint_assignments', 'assigned_by'),
      ('complaint_assignments', 'status'),
      ('complaint_assignments', 'priority'),
      ('complaint_evidence', 'complaint_id'),
      ('complaint_evidence', 'assignment_id'),
      ('complaint_evidence', 'staff_id'),
      ('complaint_evidence', 'evidence_type'),
      ('complaint_evidence', 'object_path'),
      ('complaint_evidence', 'latitude'),
      ('complaint_evidence', 'longitude'),
      ('complaints', 'current_assignment_id'),
      ('complaints', 'assigned_department')
  ) AS expected(table_name, column_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.columns AS actual
    WHERE actual.table_schema = 'public'
      AND actual.table_name = expected.table_name
      AND actual.column_name = expected.column_name
  );

  IF v_missing_columns IS NOT NULL THEN
    RAISE EXCEPTION 'Missing columns on staff tables: %', v_missing_columns;
  END IF;

  -- ---------------------------------------------------------------------------
  -- 3. Verify Row-Level Security (RLS) is Enabled on Every Table
  -- ---------------------------------------------------------------------------
  IF EXISTS (
    SELECT 1
    FROM pg_class AS relation
    JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
    WHERE namespace.nspname = 'public'
      AND relation.relname = ANY(ARRAY[
        'staff_profiles',
        'complaint_assignments',
        'complaint_evidence'
      ])
      AND NOT relation.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'RLS is not enabled on one or more staff tables.';
  END IF;

  ALTER TABLE public.staff_profiles FORCE ROW LEVEL SECURITY;
  ALTER TABLE public.complaint_assignments FORCE ROW LEVEL SECURITY;
  ALTER TABLE public.complaint_evidence FORCE ROW LEVEL SECURITY;

  -- ---------------------------------------------------------------------------
  -- 4. Verify Helper Functions Exist and Have Safe Search Paths
  -- ---------------------------------------------------------------------------
  IF to_regprocedure('public.is_active_staff()') IS NULL OR
     to_regprocedure('public.get_staff_department()') IS NULL OR
     to_regprocedure('public.get_staff_role()') IS NULL OR
     to_regprocedure('public.calculate_distance_meters(double precision,double precision,double precision,double precision)') IS NULL OR
     to_regprocedure('public.assign_complaint(uuid,uuid,text,text)') IS NULL OR
     to_regprocedure('public.accept_complaint_assignment(uuid)') IS NULL OR
     to_regprocedure('public.start_complaint_assignment(uuid)') IS NULL OR
     to_regprocedure('public.complete_complaint_assignment(uuid,text)') IS NULL OR
     to_regprocedure('public.approve_complaint_assignment(uuid,text)') IS NULL OR
     to_regprocedure('public.request_rework_complaint_assignment(uuid,text)') IS NULL OR
     to_regprocedure('public.record_complaint_evidence(uuid,text,text,text,text,bigint,double precision,double precision,double precision,text)') IS NULL THEN
    RAISE EXCEPTION 'One or more required helper/RPC functions are missing.';
  END IF;

  SELECT string_agg(rpc.proname, ', ' ORDER BY rpc.proname)
  INTO v_insecure_functions
  FROM pg_proc AS rpc
  JOIN pg_namespace AS namespace ON namespace.oid = rpc.pronamespace
  WHERE namespace.nspname = 'public'
    AND rpc.proname = ANY(ARRAY[
      'is_active_staff',
      'get_staff_department',
      'get_staff_role',
      'assign_complaint',
      'accept_complaint_assignment',
      'start_complaint_assignment',
      'complete_complaint_assignment',
      'approve_complaint_assignment',
      'request_rework_complaint_assignment',
      'record_complaint_evidence'
    ])
    AND (
      NOT rpc.prosecdef OR
      coalesce(array_to_string(rpc.proconfig, ','), '') NOT LIKE '%search_path=%'
    );

  IF v_insecure_functions IS NOT NULL THEN
    RAISE EXCEPTION 'Insecure search path on helper functions: %', v_insecure_functions;
  END IF;

  -- ---------------------------------------------------------------------------
  -- 5. Test Haversine Distance Calculation Functionality
  -- Nagpur Zero Mile (21.1498, 79.0806) to Sitabuldi Fort (21.1485, 79.0863) ~ 600m
  -- ---------------------------------------------------------------------------
  v_calc_dist := public.calculate_distance_meters(21.1498, 79.0806, 21.1485, 79.0863);
  IF v_calc_dist IS NULL OR v_calc_dist < 500.0 OR v_calc_dist > 750.0 THEN
    RAISE EXCEPTION 'Haversine distance calculation returned unexpected distance: %', v_calc_dist;
  END IF;

  -- Distance from identical coordinates must be exactly 0
  IF public.calculate_distance_meters(21.1458, 79.0882, 21.1458, 79.0882) > 0.001 THEN
    RAISE EXCEPTION 'Distance between identical points must be 0.';
  END IF;

  -- ---------------------------------------------------------------------------
  -- 6. Verify Storage Bucket Configuration
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets
    WHERE id = 'complaint-evidence' AND public = false
  ) THEN
    RAISE EXCEPTION 'Storage bucket complaint-evidence is missing or not configured as private.';
  END IF;

  -- ---------------------------------------------------------------------------
  -- 8. Verify Department Matching Rules
  -- ---------------------------------------------------------------------------
  -- 1. Insert mock auth.users with dynamic unique emails to satisfy foreign key constraints
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES
    (v_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin_' || v_admin_id || '@smartnagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now()),
    (v_road_staff_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'road_' || v_road_staff_id || '@nagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now()),
    (v_waste_staff_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'waste_' || v_waste_staff_id || '@nagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now()),
    (v_water_staff_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'water_' || v_water_staff_id || '@nagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now()),
    (v_vendor_staff_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'vendor_' || v_vendor_staff_id || '@nagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now()),
    (v_citizen_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'citizen_' || v_citizen_id || '@nagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now()),
    (v_other_citizen_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'other_' || v_other_citizen_id || '@nagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now()),
    (v_staff_1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'staff1_' || v_staff_1_id || '@nagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now()),
    (v_staff_2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'staff2_' || v_staff_2_id || '@nagpur.gov.in', 'dummy', now(), '{"provider":"email"}'::jsonb, '{}'::jsonb, now(), now());

  -- Temporary mock profiles for contract testing within rollback transaction
  INSERT INTO public.admin_profiles (id, name, email, role, is_active)
  VALUES (v_admin_id, 'Test Admin', 'admin_' || v_admin_id || '@smartnagpur.gov.in', 'superAdmin', true);

  INSERT INTO public.profiles (id, name, email, phone)
  VALUES (v_citizen_id, 'Test Citizen', 'citizen_' || v_citizen_id || '@nagpur.gov.in', '+919876543210')
  ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, phone = EXCLUDED.phone;

  INSERT INTO public.profiles (id, name, email, phone)
  VALUES (v_other_citizen_id, 'Other Citizen', 'other_' || v_other_citizen_id || '@nagpur.gov.in', '+919876543211')
  ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, phone = EXCLUDED.phone;

  INSERT INTO public.staff_profiles (id, name, email, employee_id, department, role, is_active)
  VALUES
    (v_road_staff_id, 'Road Worker', 'road_' || v_road_staff_id || '@nagpur.gov.in', 'RD-' || substr(v_road_staff_id::text, 1, 8), 'ROAD', 'FIELD_WORKER', true),
    (v_waste_staff_id, 'Waste Worker', 'waste_' || v_waste_staff_id || '@nagpur.gov.in', 'WS-' || substr(v_waste_staff_id::text, 1, 8), 'WASTE', 'FIELD_WORKER', true),
    (v_water_staff_id, 'Water Worker', 'water_' || v_water_staff_id || '@nagpur.gov.in', 'WT-' || substr(v_water_staff_id::text, 1, 8), 'WATER', 'FIELD_WORKER', true),
    (v_vendor_staff_id, 'Vendor Officer', 'vendor_' || v_vendor_staff_id || '@nagpur.gov.in', 'VN-' || substr(v_vendor_staff_id::text, 1, 8), 'VENDOR', 'OFFICER', true),
    (v_staff_1_id, 'Staff One', 'staff1_' || v_staff_1_id || '@nagpur.gov.in', 'ST1-' || substr(v_staff_1_id::text, 1, 8), 'ROAD', 'FIELD_WORKER', true),
    (v_staff_2_id, 'Staff Two', 'staff2_' || v_staff_2_id || '@nagpur.gov.in', 'ST2-' || substr(v_staff_2_id::text, 1, 8), 'ROAD', 'FIELD_WORKER', true);

  -- Setup authenticated session as admin
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, false);

  -- Test Case A: ROAD complaint -> WASTE staff (MUST BE REJECTED)
  INSERT INTO public.complaints (id, owner_id, service_type, issue, description, latitude, longitude, accuracy, location_address, contact_phone)
  VALUES (v_test_complaint_id, v_admin_id, 'roads', 'Pothole Test', 'Test pothole', 21.14, 79.08, 10.0, 'Civil Lines', '9876543210');

  BEGIN
    PERFORM public.assign_complaint(v_test_complaint_id, v_waste_staff_id, 'medium', 'Test instructions');
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Department check failed: ROAD complaint was wrongly allowed to be assigned to WASTE staff!';
  END IF;

  -- Test Case B: ROAD complaint -> ROAD staff (MUST BE ALLOWED)
  BEGIN
    PERFORM public.assign_complaint(v_test_complaint_id, v_road_staff_id, 'medium', 'Test instructions');
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
    v_err_msg := SQLERRM;
  END;
  IF v_error_caught THEN
    RAISE EXCEPTION 'Department check failed: ROAD complaint failed to assign to ROAD staff! Error: %', v_err_msg;
  END IF;

  -- Test Case C: WASTE complaint -> ROAD staff (MUST BE REJECTED)
  UPDATE public.complaints SET service_type = 'garbage' WHERE id = v_test_complaint_id;
  BEGIN
    PERFORM public.assign_complaint(v_test_complaint_id, v_road_staff_id, 'medium', 'Test instructions');
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Department check failed: WASTE complaint was wrongly allowed to be assigned to ROAD staff!';
  END IF;

  -- Test Case D: WATER complaint -> ROAD staff (MUST BE REJECTED)
  UPDATE public.complaints SET service_type = 'water' WHERE id = v_test_complaint_id;
  BEGIN
    PERFORM public.assign_complaint(v_test_complaint_id, v_road_staff_id, 'medium', 'Test instructions');
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Department check failed: WATER complaint was wrongly allowed to be assigned to ROAD staff!';
  END IF;

  -- Test Case E: VENDOR complaint -> WASTE staff (MUST BE REJECTED)
  UPDATE public.complaints SET service_type = 'vendor' WHERE id = v_test_complaint_id;
  BEGIN
    PERFORM public.assign_complaint(v_test_complaint_id, v_waste_staff_id, 'medium', 'Test instructions');
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Department check failed: VENDOR complaint was wrongly allowed to be assigned to WASTE staff!';
  END IF;

  -- ---------------------------------------------------------------------------
  -- 9. Verify Task State Machine Lifecycle Transitions
  -- ---------------------------------------------------------------------------
  -- Reset complaint to road and assign to road staff
  UPDATE public.complaints SET service_type = 'roads' WHERE id = v_test_complaint_id;
  v_assigned_result := public.assign_complaint(v_test_complaint_id, v_road_staff_id, 'urgent', 'Fill pothole');
  v_task_assignment_id := (v_assigned_result->>'assignmentId')::uuid;

  -- Test 9A: Unauthorized staff (waste worker) cannot accept road worker's assignment
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_waste_staff_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    PERFORM public.accept_complaint_assignment(v_task_assignment_id);
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Staff was allowed to accept another staff member task!';
  END IF;

  -- Test 9B: Road worker cannot directly complete without accepting and starting
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_road_staff_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    PERFORM public.complete_complaint_assignment(v_task_assignment_id, 'Premature completion');
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'State machine breach: Staff was allowed to complete task directly from assigned state!';
  END IF;

  -- Test 9C: Valid transition: assigned -> accepted
  PERFORM public.accept_complaint_assignment(v_task_assignment_id);
  IF NOT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE id = v_task_assignment_id AND status = 'accepted' AND accepted_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Failed to transition assignment status to accepted!';
  END IF;

  -- Test 9D: Valid transition: accepted -> inProgress
  PERFORM public.start_complaint_assignment(v_task_assignment_id);
  IF NOT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE id = v_task_assignment_id AND status = 'inProgress' AND started_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Failed to transition assignment status to inProgress!';
  END IF;

  -- Verify complaint status updated to inProgress
  IF NOT EXISTS (
    SELECT 1 FROM public.complaints
    WHERE id = v_test_complaint_id AND status = 'inProgress'
  ) THEN
    RAISE EXCEPTION 'Complaint status was not updated to inProgress!';
  END IF;

  -- Test 9E: Valid transition: inProgress -> completed (Work Submitted for Verification)
  PERFORM public.complete_complaint_assignment(v_task_assignment_id, 'Pothole patch completed successfully.');
  IF NOT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE id = v_task_assignment_id AND status = 'completed' AND completed_at IS NOT NULL AND notes LIKE '%Pothole patch%'
  ) THEN
    RAISE EXCEPTION 'Failed to transition assignment status to completed!';
  END IF;

  -- Verify complaint status is underReview (NOT resolved yet)
  IF NOT EXISTS (
    SELECT 1 FROM public.complaints
    WHERE id = v_test_complaint_id AND status = 'underReview'
  ) THEN
    RAISE EXCEPTION 'Complaint status was wrongly resolved or not set to underReview on staff completion!';
  END IF;

  -- Test 9F: Staff CANNOT approve their own work
  BEGIN
    PERFORM public.approve_complaint_assignment(v_task_assignment_id, 'Self approval attempt');
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Staff was allowed to approve their own work!';
  END IF;

  -- Test 9G: Admin requests rework
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, false);
  PERFORM public.request_rework_complaint_assignment(v_task_assignment_id, 'Level the road surface smoothly');
  IF NOT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE id = v_task_assignment_id AND status = 'reworkRequired' AND rejection_reason LIKE '%Level the road%'
  ) THEN
    RAISE EXCEPTION 'Failed to transition assignment status to reworkRequired!';
  END IF;

  -- Verify complaint status transitioned back to inProgress
  IF NOT EXISTS (
    SELECT 1 FROM public.complaints
    WHERE id = v_test_complaint_id AND status = 'inProgress'
  ) THEN
    RAISE EXCEPTION 'Complaint status was not updated to inProgress during rework request!';
  END IF;

  -- Test 9H: Staff restarts rework (reworkRequired -> inProgress)
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_road_staff_id::text, 'role', 'authenticated')::text, false);
  PERFORM public.start_complaint_assignment(v_task_assignment_id);
  IF NOT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE id = v_task_assignment_id AND status = 'inProgress'
  ) THEN
    RAISE EXCEPTION 'Failed to restart rework into inProgress status!';
  END IF;

  -- Test 9I: Staff resubmits work (inProgress -> completed)
  PERFORM public.complete_complaint_assignment(v_task_assignment_id, 'Road surface re-leveled and sealed.');
  IF NOT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE id = v_task_assignment_id AND status = 'completed'
  ) THEN
    RAISE EXCEPTION 'Failed to re-complete assignment!';
  END IF;

  -- Verify complaint status is back to underReview
  IF NOT EXISTS (
    SELECT 1 FROM public.complaints
    WHERE id = v_test_complaint_id AND status = 'underReview'
  ) THEN
    RAISE EXCEPTION 'Complaint status was not set to underReview on rework completion!';
  END IF;

  -- Test 9J: Admin approves verified work (completed -> approved -> complaint resolved)
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, false);
  PERFORM public.approve_complaint_assignment(v_task_assignment_id, 'Verified on-site by supervisor.');
  IF NOT EXISTS (
    SELECT 1 FROM public.complaint_assignments
    WHERE id = v_task_assignment_id AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'Failed to approve assignment!';
  END IF;

  -- Verify complaint status is now resolved
  IF NOT EXISTS (
    SELECT 1 FROM public.complaints
    WHERE id = v_test_complaint_id AND status = 'resolved'
  ) THEN
    RAISE EXCEPTION 'Complaint status was not updated to resolved upon administrative approval!';
  END IF;

  -- Test 9K: Approved task cannot be approved or reworked again
  BEGIN
    PERFORM public.approve_complaint_assignment(v_task_assignment_id);
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'State machine breach: Approved task was allowed to be approved again!';
  END IF;

  -- ---------------------------------------------------------------------------
  -- 10. Step 8B: GPS Location Verification & Field Evidence Contract Tests
  -- ---------------------------------------------------------------------------
  -- 10.1 Create test complaint with precise coordinates (Sitabuldi, Nagpur: 21.1458, 79.0882)
  INSERT INTO public.complaints (
    id,
    owner_id,
    service_type,
    issue,
    description,
    location_address,
    latitude,
    longitude,
    accuracy,
    contact_phone,
    status
  ) VALUES (
    v_ev_complaint_id,
    v_citizen_id,
    'roads',
    'Pothole on Main Road',
    'Large pothole requiring asphalt filling.',
    'Sitabuldi Main Road, Nagpur',
    21.1458,
    79.0882,
    10.0,
    '+919876543210',
    'submitted'
  );

  -- 10.2 Admin assigns complaint to Road Staff 1
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, false);
  SELECT (public.assign_complaint(v_ev_complaint_id, v_staff_1_id, 'high', 'Deploy road crew immediately.'))->>'assignmentId'
  INTO v_ev_assignment_id;

  -- 10.3 Staff accepts and starts assignment
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_staff_1_id::text, 'role', 'authenticated')::text, false);
  PERFORM public.accept_complaint_assignment(v_ev_assignment_id);
  PERFORM public.start_complaint_assignment(v_ev_assignment_id);

  -- 10.4 Staff uploads Before-Work photo within 50m radius (21.1459, 79.0883, accuracy = 15m) -> Verified
  SELECT public.record_complaint_evidence(
    v_ev_assignment_id,
    'beforeWork',
    format('%s/%s/%s/before_work_photo.jpg', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
    'before_work_photo.jpg',
    'image/jpeg',
    245000,
    21.1459,
    79.0883,
    15.0,
    'Pre-work site inspection.'
  ) INTO v_ev_result;

  IF (v_ev_result->>'isGeoVerified')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'Evidence within 50m radius was not marked as geo-verified!';
  END IF;

  IF (v_ev_result->>'distanceFromComplaintMeters')::double precision > 100.0 THEN
    RAISE EXCEPTION 'Distance calculation incorrect: % meters', (v_ev_result->>'distanceFromComplaintMeters');
  END IF;

  -- 10.5 Staff uploads After-Work photo outside 100m radius (21.1500, 79.0950, ~800m away) -> isGeoVerified = false
  SELECT public.record_complaint_evidence(
    v_ev_assignment_id,
    'afterWork',
    format('%s/%s/%s/after_work_photo.jpg', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
    'after_work_photo.jpg',
    'image/jpeg',
    310000,
    21.1500,
    79.0950,
    10.0,
    'Post-repair inspection from afar.'
  ) INTO v_ev_result;

  IF (v_ev_result->>'isGeoVerified')::boolean IS TRUE THEN
    RAISE EXCEPTION 'Evidence outside 100m radius was incorrectly marked as geo-verified!';
  END IF;

  -- 10.6 Staff uploads Inspection PDF (up to 10MB) -> Verified
  SELECT public.record_complaint_evidence(
    v_ev_assignment_id,
    'inspectionReport',
    format('%s/%s/%s/inspection_report.pdf', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
    'inspection_report.pdf',
    'application/pdf',
    1024000,
    21.1458,
    79.0882,
    5.0,
    'Signed engineer report.'
  ) INTO v_ev_result;

  IF v_ev_result->>'evidenceId' IS NULL THEN
    RAISE EXCEPTION 'Failed to record inspection report evidence!';
  END IF;

  -- 10.7 Security: Staff 2 cannot upload evidence to Staff 1 assignment
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_staff_2_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s/tampered.jpg', v_staff_2_id, v_ev_complaint_id, v_ev_assignment_id),
      'tampered.jpg',
      'image/jpeg',
      100000,
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Staff 2 was able to upload evidence to Staff 1 assignment!';
  END IF;

  -- 10.8 Security: Invalid path structure rejected
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_staff_1_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      'invalid_folder/invalid_name.jpg',
      'invalid_name.jpg',
      'image/jpeg',
      100000,
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Invalid storage path was accepted!';
  END IF;

  -- 10.9 Security: File > 10MB rejected
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s/huge.jpg', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
      'huge.jpg',
      'image/jpeg',
      15000000, -- 15MB
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: File exceeding 10MB was accepted!';
  END IF;

  -- 10.10 RLS: Citizen can view evidence for their own complaint
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_citizen_id::text, 'role', 'authenticated')::text, false);
  IF NOT EXISTS (
    SELECT 1 FROM public.complaint_evidence WHERE complaint_id = v_ev_complaint_id
  ) THEN
    RAISE EXCEPTION 'RLS failure: Citizen cannot view evidence for their own complaint!';
  END IF;

  -- 10.11 RLS: Other citizen cannot view evidence
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_other_citizen_id::text, 'role', 'authenticated')::text, false);
  IF EXISTS (
    SELECT 1 FROM public.complaint_evidence WHERE complaint_id = v_ev_complaint_id
  ) THEN
    RAISE EXCEPTION 'RLS breach: Unrelated citizen was able to view complaint evidence!';
  END IF;

  -- 10.12 Security: Path traversal attempt with '..' rejected
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_staff_1_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s/../../other_staff/stolen.jpg', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
      'stolen.jpg',
      'image/jpeg',
      100000,
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Path traversal with .. was accepted!';
  END IF;

  -- 10.13 Security: Backslash in path rejected
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s%cevil.jpg', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id, 92),
      'evil.jpg',
      'image/jpeg',
      100000,
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Backslash character in object path was accepted!';
  END IF;

  -- 10.14 Security: Photo evidence with PDF MIME type rejected
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s/fake_photo.pdf', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
      'fake_photo.pdf',
      'application/pdf',
      100000,
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: PDF MIME type accepted for beforeWork photo!';
  END IF;

  -- 10.15 Security: Impossible latitude (> 90.0) rejected
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s/valid_name.jpg', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
      'valid_name.jpg',
      'image/jpeg',
      100000,
      125.0, -- Impossible latitude > 90
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Impossible latitude > 90 was accepted!';
  END IF;

  -- 10.16 Security: Negative GPS accuracy rejected
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s/valid_name2.jpg', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
      'valid_name2.jpg',
      'image/jpeg',
      100000,
      21.1458,
      79.0882,
      -5.0 -- Negative accuracy
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Negative accuracy was accepted!';
  END IF;

  -- 10.17 Security: Duplicate beforeWork photo in non-rework state rejected
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s/second_before.jpg', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
      'second_before.jpg',
      'image/jpeg',
      100000,
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Duplicate beforeWork evidence was accepted in non-rework state!';
  END IF;

  -- 10.18 Security: Citizen calling staff evidence RPC is rejected
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_citizen_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'beforeWork',
      format('%s/%s/%s/citizen_intruder.jpg', v_citizen_id, v_ev_complaint_id, v_ev_assignment_id),
      'citizen_intruder.jpg',
      'image/jpeg',
      100000,
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Citizen was able to call record_complaint_evidence RPC!';
  END IF;

  -- 10.19 Security: Evidence cannot be added when assignment is completed
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_staff_1_id::text, 'role', 'authenticated')::text, false);
  PERFORM public.complete_complaint_assignment(v_ev_assignment_id, 'All work done.');

  BEGIN
    PERFORM public.record_complaint_evidence(
      v_ev_assignment_id,
      'inspectionReport',
      format('%s/%s/%s/late_report.pdf', v_staff_1_id, v_ev_complaint_id, v_ev_assignment_id),
      'late_report.pdf',
      'application/pdf',
      100000,
      21.1458,
      79.0882,
      10.0
    );
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Evidence was allowed on completed assignment!';
  END IF;

  -- =========================================================================
  -- 11. Step 10: Admin Operations & Verification Dashboard Tests
  -- =========================================================================
  -- 11.1 Unauthorized citizen calling get_admin_operations_dashboard is rejected
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_citizen_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    PERFORM public.get_admin_operations_dashboard();
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Citizen was able to call get_admin_operations_dashboard!';
  END IF;

  -- 11.2 Active Admin calling get_admin_operations_dashboard succeeds
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, false);
  v_dashboard := public.get_admin_operations_dashboard();

  IF v_dashboard IS NULL THEN
    RAISE EXCEPTION 'Failed: get_admin_operations_dashboard returned NULL';
  END IF;

  IF NOT v_dashboard ? 'verification_queue' THEN
    RAISE EXCEPTION 'Failed: dashboard JSON missing verification_queue key';
  END IF;

  IF NOT v_dashboard ? 'staff_workload_summary' THEN
    RAISE EXCEPTION 'Failed: dashboard JSON missing staff_workload_summary key';
  END IF;

  -- 11.3 Verification queue contains the completed assignment from Step 8A/8C
  IF jsonb_array_length(v_dashboard->'verification_queue') < 1 THEN
    RAISE EXCEPTION 'Failed: verification_queue did not contain completed tasks!';
  END IF;

  -- 11.4 Department filter scopes verification queue correctly
  v_dashboard := public.get_admin_operations_dashboard(p_department := 'ROAD');
  IF jsonb_array_length(v_dashboard->'verification_queue') < 1 THEN
    RAISE EXCEPTION 'Failed: ROAD department filter returned empty queue when ROAD task exists!';
  END IF;

  v_dashboard := public.get_admin_operations_dashboard(p_department := 'WATER');
  IF jsonb_array_length(v_dashboard->'verification_queue') > 0 THEN
    RAISE EXCEPTION 'Failed: WATER department filter contained non-WATER tasks!';
  END IF;

  -- =========================================================================
  -- 12. Step 11: Security & RLS Hardening Regression Tests
  -- =========================================================================
  -- 12.1 Citizen calling get_complaint_stats() is rejected
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_citizen_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    PERFORM public.get_complaint_stats();
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Citizen was able to call get_complaint_stats!';
  END IF;

  -- 12.2 Citizen calling get_admin_pending_complaints() is rejected
  BEGIN
    PERFORM public.get_admin_pending_complaints();
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Citizen was able to call get_admin_pending_complaints!';
  END IF;

  -- 12.3 Citizen calling get_admin_complaint_details() is rejected
  BEGIN
    PERFORM public.get_admin_complaint_details(v_ev_complaint_id::text);
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Citizen was able to call get_admin_complaint_details!';
  END IF;

  -- 12.4 Citizen calling get_admin_vendor_applications() is rejected
  BEGIN
    PERFORM public.get_admin_vendor_applications();
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Citizen was able to call get_admin_vendor_applications!';
  END IF;

  -- 12.5 Staff 1 attempting to escalate their own role from FIELD_WORKER to SUPERVISOR is rejected
  PERFORM set_config('request.jwt.claims', json_build_object('sub', v_staff_1_id::text, 'role', 'authenticated')::text, false);
  BEGIN
    UPDATE public.staff_profiles
    SET role = 'SUPERVISOR'
    WHERE id = v_staff_1_id;
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Staff 1 was able to self-escalate role to SUPERVISOR!';
  END IF;

  -- 12.6 Staff 1 attempting to modify department is rejected
  BEGIN
    UPDATE public.staff_profiles
    SET department = 'WATER'
    WHERE id = v_staff_1_id;
    v_error_caught := false;
  EXCEPTION WHEN OTHERS THEN
    v_error_caught := true;
  END;
  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'Security breach: Staff 1 was able to change department!';
  END IF;

  -- 12.7 Staff 1 updating permitted fields (phone, on-duty) succeeds
  UPDATE public.staff_profiles
  SET phone = '+919988776655',
      is_on_duty = false,
      last_active_at = now()
  WHERE id = v_staff_1_id;

  IF (SELECT is_on_duty FROM public.staff_profiles WHERE id = v_staff_1_id) IS NOT FALSE THEN
    RAISE EXCEPTION 'Failed: Staff 1 on_duty status update did not persist!';
  END IF;

  -- Restore on_duty for subsequent flows
  UPDATE public.staff_profiles
  SET is_on_duty = true
  WHERE id = v_staff_1_id;

  -- =========================================================================
  -- 13. STEP 12 PERFORMANCE & RESILIENCE: INDEX CONTRACT TESTS
  -- =========================================================================
  -- 13.1 Verify high performance indexes exist
  SELECT count(*) INTO v_index_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND indexname IN (
      'idx_complaints_status_created',
      'idx_complaints_created',
      'idx_vendor_applications_status_created',
      'idx_vendor_applications_created',
      'idx_admin_reviews_lookup',
      'idx_user_suspensions_active',
      'idx_admin_notifications_created',
      'idx_complaint_assignments_status_assigned'
    );

  IF v_index_count < 8 THEN
    RAISE EXCEPTION 'Performance regression: Expected 8 production indexes, found %', v_index_count;
  END IF;

  RAISE NOTICE 'All Staff Database Schema, Security, Verification, GPS Evidence, Admin Operations, and Step 12 Performance Tests PASSED successfully!';
END $$;

ROLLBACK;