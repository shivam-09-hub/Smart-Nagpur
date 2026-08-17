-- Smart Nagpur Admin Database Migration
-- Run this in the Supabase SQL Editor after 202608170001_smart_nagpur_backend.sql

-- 1. Admin Tables
CREATE TABLE IF NOT EXISTS public.admin_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text DEFAULT '',
  role text NOT NULL DEFAULT 'complaintReviewer' CHECK (role IN ('superAdmin', 'complaintReviewer', 'vendorReviewer', 'reportViewer', 'notificationManager', 'userManager')),
  is_active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_login_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.admin_notifications (
  id text PRIMARY KEY,
  title text NOT NULL,
  body text NOT NULL,
  category text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  sender_id uuid REFERENCES public.admin_profiles(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public.admin_reviews (
  id text PRIMARY KEY,
  item_type text NOT NULL CHECK (item_type IN ('complaint', 'application')),
  item_id text NOT NULL,
  reviewed_by uuid NOT NULL REFERENCES public.admin_profiles(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'moreInfoNeeded', 'onHold')),
  comments text DEFAULT '',
  rating integer CHECK (rating >= 1 AND rating <= 5),
  attachment_notes text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(item_type, item_id)
);

CREATE TABLE IF NOT EXISTS public.user_suspensions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  suspended_by uuid NOT NULL REFERENCES public.admin_profiles(id) ON DELETE RESTRICT,
  reason text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  lifted_at timestamptz
);

-- 2. Enable Row-Level Security on Admin Tables
ALTER TABLE public.admin_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_suspensions ENABLE ROW LEVEL SECURITY;

-- 3. Security Definer Helper Functions (Prevent Infinite Recursion)
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_profiles
    WHERE id = auth.uid() AND role = 'superAdmin' AND is_active = true
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_active_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_profiles
    WHERE id = auth.uid() AND is_active = true
  );
END;
$$;

-- 4. RLS Policies on Admin Tables
DROP POLICY IF EXISTS admin_profiles_select ON public.admin_profiles;
CREATE POLICY admin_profiles_select ON public.admin_profiles
  FOR SELECT USING (auth.uid() = id OR public.is_super_admin());

DROP POLICY IF EXISTS admin_profiles_update ON public.admin_profiles;
CREATE POLICY admin_profiles_update ON public.admin_profiles
  FOR UPDATE USING (auth.uid() = id OR public.is_super_admin());

DROP POLICY IF EXISTS admin_notifications_select ON public.admin_notifications;
CREATE POLICY admin_notifications_select ON public.admin_notifications
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_notifications_insert ON public.admin_notifications;
CREATE POLICY admin_notifications_insert ON public.admin_notifications
  FOR INSERT WITH CHECK (public.is_active_admin());

DROP POLICY IF EXISTS admin_reviews_select ON public.admin_reviews;
CREATE POLICY admin_reviews_select ON public.admin_reviews
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_reviews_insert ON public.admin_reviews;
CREATE POLICY admin_reviews_insert ON public.admin_reviews
  FOR INSERT WITH CHECK (public.is_active_admin());

DROP POLICY IF EXISTS admin_reviews_update ON public.admin_reviews;
CREATE POLICY admin_reviews_update ON public.admin_reviews
  FOR UPDATE USING (public.is_active_admin());

DROP POLICY IF EXISTS user_suspensions_select ON public.user_suspensions;
CREATE POLICY user_suspensions_select ON public.user_suspensions
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS user_suspensions_insert ON public.user_suspensions;
CREATE POLICY user_suspensions_insert ON public.user_suspensions
  FOR INSERT WITH CHECK (public.is_active_admin());

-- 5. RLS Policies for Admin Access to Citizen Data
DROP POLICY IF EXISTS admin_profiles_read_all ON public.profiles;
CREATE POLICY admin_profiles_read_all ON public.profiles
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_complaints_read_all ON public.complaints;
CREATE POLICY admin_complaints_read_all ON public.complaints
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_complaints_update ON public.complaints;
CREATE POLICY admin_complaints_update ON public.complaints
  FOR UPDATE USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_complaint_photos_read_all ON public.complaint_photos;
CREATE POLICY admin_complaint_photos_read_all ON public.complaint_photos
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_complaint_timeline_read_all ON public.complaint_timeline;
CREATE POLICY admin_complaint_timeline_read_all ON public.complaint_timeline
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_complaint_timeline_insert ON public.complaint_timeline;
CREATE POLICY admin_complaint_timeline_insert ON public.complaint_timeline
  FOR INSERT WITH CHECK (public.is_active_admin());

DROP POLICY IF EXISTS admin_vendor_applications_read_all ON public.vendor_applications;
CREATE POLICY admin_vendor_applications_read_all ON public.vendor_applications
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_vendor_applications_update ON public.vendor_applications;
CREATE POLICY admin_vendor_applications_update ON public.vendor_applications
  FOR UPDATE USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_vendor_documents_read_all ON public.vendor_documents;
CREATE POLICY admin_vendor_documents_read_all ON public.vendor_documents
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_vendor_timeline_read_all ON public.vendor_timeline;
CREATE POLICY admin_vendor_timeline_read_all ON public.vendor_timeline
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_vendor_timeline_insert ON public.vendor_timeline;
CREATE POLICY admin_vendor_timeline_insert ON public.vendor_timeline
  FOR INSERT WITH CHECK (public.is_active_admin());

DROP POLICY IF EXISTS admin_notifications_read_all ON public.notifications;
CREATE POLICY admin_notifications_read_all ON public.notifications
  FOR SELECT USING (public.is_active_admin());

DROP POLICY IF EXISTS admin_notifications_insert_all ON public.notifications;
CREATE POLICY admin_notifications_insert_all ON public.notifications
  FOR INSERT WITH CHECK (public.is_active_admin());

-- 6. Storage Policies for Admin Access
DROP POLICY IF EXISTS admin_storage_complaint_photos ON storage.objects;
CREATE POLICY admin_storage_complaint_photos ON storage.objects
  FOR SELECT USING (bucket_id = 'complaint-photos' AND public.is_active_admin());

DROP POLICY IF EXISTS admin_storage_vendor_documents ON storage.objects;
CREATE POLICY admin_storage_vendor_documents ON storage.objects
  FOR SELECT USING (bucket_id = 'vendor-documents' AND public.is_active_admin());

-- 7. Analytics & Dashboard RPC Functions (Drop first to allow return type changes)
DROP FUNCTION IF EXISTS public.get_complaint_stats() CASCADE;
DROP FUNCTION IF EXISTS public.get_admin_stats() CASCADE;
DROP FUNCTION IF EXISTS public.get_vendor_stats() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_stats() CASCADE;
DROP FUNCTION IF EXISTS public.get_notification_stats() CASCADE;
DROP FUNCTION IF EXISTS public.get_complaints_by_service() CASCADE;
DROP FUNCTION IF EXISTS public.get_complaints_by_status() CASCADE;
DROP FUNCTION IF EXISTS public.get_applications_by_status() CASCADE;
DROP FUNCTION IF EXISTS public.get_daily_stats(integer) CASCADE;
DROP FUNCTION IF EXISTS public.get_monthly_report(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.get_admin_pending_complaints(integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.get_admin_complaint_details(text) CASCADE;
DROP FUNCTION IF EXISTS public.get_admin_vendor_applications(integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.get_admin_vendor_application_details(text) CASCADE;
DROP FUNCTION IF EXISTS public.admin_update_complaint_status(text, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.admin_update_vendor_status(text, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.suspend_user(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.reactivate_user(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.send_broadcast_notification(text, text, text) CASCADE;

CREATE OR REPLACE FUNCTION public.get_complaint_stats()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'total', (SELECT count(*)::int FROM public.complaints),
    'pending', (SELECT count(*)::int FROM public.complaints WHERE status = 'submitted'),
    'resolved', (SELECT count(*)::int FROM public.complaints WHERE status = 'resolved'),
    'byService', COALESCE(
      (
        SELECT jsonb_object_agg(service_type, count)
        FROM (
          SELECT service_type, count(*)::int AS count
          FROM public.complaints
          GROUP BY service_type
        ) t
      ),
      '{}'::jsonb
    ),
    'byStatus', COALESCE(
      (
        SELECT jsonb_object_agg(status, count)
        FROM (
          SELECT status, count(*)::int AS count
          FROM public.complaints
          GROUP BY status
        ) t
      ),
      '{}'::jsonb
    )
  );
$$;

CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_complaint_stats();
$$;

CREATE OR REPLACE FUNCTION public.get_vendor_stats()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'total', (SELECT count(*)::int FROM public.vendor_applications),
    'pending', (SELECT count(*)::int FROM public.vendor_applications WHERE status = 'submitted'),
    'approved', (SELECT count(*)::int FROM public.vendor_applications WHERE status = 'approved'),
    'rejected', (SELECT count(*)::int FROM public.vendor_applications WHERE status = 'rejected')
  );
$$;

CREATE OR REPLACE FUNCTION public.get_user_stats()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'total', (SELECT count(*)::int FROM public.profiles),
    'active', (
      SELECT count(*)::int FROM public.profiles p
      WHERE NOT EXISTS (
        SELECT 1 FROM public.user_suspensions s
        WHERE s.user_id = p.id AND s.is_active = true
      )
    )
  );
$$;

CREATE OR REPLACE FUNCTION public.get_notification_stats()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'total', (SELECT count(*)::int FROM public.notifications),
    'unread', (SELECT count(*)::int FROM public.notifications WHERE is_read = false)
  );
$$;

CREATE OR REPLACE FUNCTION public.get_complaints_by_service()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT jsonb_object_agg(service_type, count)
      FROM (
        SELECT service_type, count(*)::int AS count
        FROM public.complaints
        GROUP BY service_type
        ORDER BY count DESC
      ) t
    ),
    '{}'::jsonb
  );
$$;

CREATE OR REPLACE FUNCTION public.get_complaints_by_status()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT jsonb_object_agg(status, count)
      FROM (
        SELECT status, count(*)::int AS count
        FROM public.complaints
        GROUP BY status
        ORDER BY count DESC
      ) t
    ),
    '{}'::jsonb
  );
$$;

CREATE OR REPLACE FUNCTION public.get_applications_by_status()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT jsonb_object_agg(status, count)
      FROM (
        SELECT status, count(*)::int AS count
        FROM public.vendor_applications
        GROUP BY status
        ORDER BY count DESC
      ) t
    ),
    '{}'::jsonb
  );
$$;

CREATE OR REPLACE FUNCTION public.get_daily_stats(days integer DEFAULT 30)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'date', to_char(t.date, 'YYYY-MM-DD'),
        'complaints', t.complaints_count,
        'applications', t.applications_count,
        'users', t.users_count
      )
    ),
    '[]'::jsonb
  )
  FROM (
    SELECT 
      current_date - (s::integer) AS date,
      (SELECT count(*)::int FROM public.complaints WHERE created_at::date = current_date - (s::integer)) AS complaints_count,
      (SELECT count(*)::int FROM public.vendor_applications WHERE created_at::date = current_date - (s::integer)) AS applications_count,
      (SELECT count(*)::int FROM public.profiles WHERE created_at::date = current_date - (s::integer)) AS users_count
    FROM generate_series(0, days - 1) s
    ORDER BY s DESC
  ) t;
$$;

CREATE OR REPLACE FUNCTION public.get_monthly_report(month integer, year integer)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'month', month,
    'year', year,
    'complaints_submitted', (
      SELECT count(*)::int FROM public.complaints
      WHERE EXTRACT(MONTH FROM created_at) = month 
        AND EXTRACT(YEAR FROM created_at) = year
    ),
    'complaints_resolved', (
      SELECT count(*)::int FROM public.complaints
      WHERE EXTRACT(MONTH FROM updated_at) = month 
        AND EXTRACT(YEAR FROM updated_at) = year
        AND status = 'resolved'
    ),
    'applications_submitted', (
      SELECT count(*)::int FROM public.vendor_applications
      WHERE EXTRACT(MONTH FROM created_at) = month
        AND EXTRACT(YEAR FROM created_at) = year
    ),
    'applications_approved', (
      SELECT count(*)::int FROM public.vendor_applications
      WHERE EXTRACT(MONTH FROM updated_at) = month 
        AND EXTRACT(YEAR FROM updated_at) = year
        AND status = 'approved'
    ),
    'new_users', (
      SELECT count(*)::int FROM public.profiles
      WHERE EXTRACT(MONTH FROM created_at) = month
        AND EXTRACT(YEAR FROM created_at) = year
    )
  );
$$;

-- 8. Admin Data Retrieval RPCs
CREATE OR REPLACE FUNCTION public.get_admin_pending_complaints(
  p_limit int DEFAULT 50,
  p_offset int DEFAULT 0,
  p_status text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(public._complaint_remote(c.id)),
    '[]'::jsonb
  )
  FROM (
    SELECT id
    FROM public.complaints
    WHERE (p_status IS NULL OR status = p_status)
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) c;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_complaint_details(p_id text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF p_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    SELECT id INTO v_id FROM public.complaints WHERE id = p_id::uuid;
  ELSE
    SELECT id INTO v_id FROM public.complaints WHERE public_id = p_id;
  END IF;

  IF v_id IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN public._complaint_remote(v_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_vendor_applications(
  p_limit int DEFAULT 50,
  p_offset int DEFAULT 0,
  p_status text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(public._vendor_application_remote(v.id)),
    '[]'::jsonb
  )
  FROM (
    SELECT id
    FROM public.vendor_applications
    WHERE (p_status IS NULL OR status = p_status)
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) v;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_vendor_application_details(p_id text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF p_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    SELECT id INTO v_id FROM public.vendor_applications WHERE id = p_id::uuid;
  ELSE
    SELECT id INTO v_id FROM public.vendor_applications WHERE public_id = p_id;
  END IF;

  IF v_id IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN public._vendor_application_remote(v_id);
END;
$$;

-- 9. Transactional Workflow Mutation RPCs (Two-Way Sync)
CREATE OR REPLACE FUNCTION public.admin_update_complaint_status(
  p_complaint_id text,
  p_status text,
  p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_owner_id uuid;
  v_public_id text;
  v_service text;
  v_issue text;
  v_title text;
  v_msg text;
BEGIN
  IF NOT public.is_active_admin() THEN
    RAISE EXCEPTION 'Unauthorized: only active administrators can update complaint status';
  END IF;

  IF p_complaint_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    SELECT id, owner_id, public_id, service_type, issue 
    INTO v_id, v_owner_id, v_public_id, v_service, v_issue 
    FROM public.complaints WHERE id = p_complaint_id::uuid;
  ELSE
    SELECT id, owner_id, public_id, service_type, issue 
    INTO v_id, v_owner_id, v_public_id, v_service, v_issue 
    FROM public.complaints WHERE public_id = p_complaint_id;
  END IF;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'Complaint % not found', p_complaint_id;
  END IF;

  -- 1. Update complaint status
  UPDATE public.complaints
  SET status = p_status, updated_at = now()
  WHERE id = v_id;

  -- 2. Construct timeline title and message
  v_title := CASE p_status
    WHEN 'underReview' THEN 'Under Review'
    WHEN 'assigned' THEN 'Assigned to Municipal Team'
    WHEN 'inProgress' THEN 'Work in Progress'
    WHEN 'resolved' THEN 'Complaint Resolved'
    WHEN 'rejected' THEN 'Complaint Rejected'
    WHEN 'moreInformationRequired' THEN 'More Information Required'
    ELSE 'Status Updated'
  END;

  v_msg := CASE
    WHEN p_notes IS NOT NULL AND btrim(p_notes) <> '' THEN p_notes
    WHEN p_status = 'resolved' THEN 'Civic work completed and verified by municipal authority.'
    WHEN p_status = 'rejected' THEN 'Complaint could not be processed under current municipal guidelines.'
    WHEN p_status = 'inProgress' THEN 'Field team dispatched to resolve the reported issue.'
    ELSE 'Your complaint status has been updated to ' || v_title
  END;

  -- 3. Insert timeline entry for citizen tracking
  INSERT INTO public.complaint_timeline (
    complaint_id,
    owner_id,
    title,
    occurred_at,
    message,
    is_completed
  ) VALUES (
    v_id,
    v_owner_id,
    v_title,
    now(),
    v_msg,
    true
  );

  -- 4. Send notification to the citizen
  INSERT INTO public.notifications (
    id,
    owner_id,
    title,
    body,
    category,
    destination,
    reference_id,
    is_read,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_owner_id,
    v_public_id || ': ' || v_title,
    v_msg,
    'requests',
    'complaint',
    v_public_id,
    false,
    now(),
    now()
  );

  RETURN public._complaint_remote(v_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_update_vendor_status(
  p_application_id text,
  p_status text,
  p_notes text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_owner_id uuid;
  v_public_id text;
  v_business text;
  v_title text;
  v_msg text;
BEGIN
  IF NOT public.is_active_admin() THEN
    RAISE EXCEPTION 'Unauthorized: only active administrators can update vendor applications';
  END IF;

  IF p_application_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    SELECT id, owner_id, public_id, business_name
    INTO v_id, v_owner_id, v_public_id, v_business
    FROM public.vendor_applications WHERE id = p_application_id::uuid;
  ELSE
    SELECT id, owner_id, public_id, business_name
    INTO v_id, v_owner_id, v_public_id, v_business
    FROM public.vendor_applications WHERE public_id = p_application_id;
  END IF;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'Vendor application % not found', p_application_id;
  END IF;

  -- 1. Update vendor application status
  UPDATE public.vendor_applications
  SET status = p_status, updated_at = now()
  WHERE id = v_id;

  -- 2. Mark previous timeline entries as non-current
  UPDATE public.vendor_timeline
  SET is_current = false
  WHERE vendor_application_id = v_id;

  -- 3. Construct timeline title and message
  v_title := CASE p_status
    WHEN 'documentsVerified' THEN 'Documents Verified'
    WHEN 'underReview' THEN 'Under Administrative Review'
    WHEN 'locationAssessment' THEN 'Location Assessment in Progress'
    WHEN 'approved' THEN 'Application Approved'
    WHEN 'permissionIssued' THEN 'Vendor Certificate & Permission Issued'
    WHEN 'changesRequired' THEN 'Modifications Required'
    WHEN 'rejected' THEN 'Application Rejected'
    ELSE 'Status Updated'
  END;

  v_msg := CASE
    WHEN p_notes IS NOT NULL AND btrim(p_notes) <> '' THEN p_notes
    WHEN p_status = 'approved' THEN 'Your vending application for ' || v_business || ' has been approved.'
    WHEN p_status = 'rejected' THEN 'Your application does not meet the specified municipal vendor criteria.'
    WHEN p_status = 'permissionIssued' THEN 'Your official street vending permit has been granted.'
    ELSE 'Status updated to ' || v_title
  END;

  -- 4. Insert new timeline entry
  INSERT INTO public.vendor_timeline (
    vendor_application_id,
    owner_id,
    title,
    occurred_at,
    message,
    is_completed,
    is_current
  ) VALUES (
    v_id,
    v_owner_id,
    v_title,
    now(),
    v_msg,
    true,
    true
  );

  -- 5. Notify the citizen
  INSERT INTO public.notifications (
    id,
    owner_id,
    title,
    body,
    category,
    destination,
    reference_id,
    is_read,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_owner_id,
    v_public_id || ': ' || v_title,
    v_msg,
    'requests',
    'vendorApplication',
    v_public_id,
    false,
    now(),
    now()
  );

  RETURN public._vendor_application_remote(v_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.suspend_user(user_id uuid, reason text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_active_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  INSERT INTO public.user_suspensions (user_id, suspended_by, reason, is_active)
  VALUES (user_id, auth.uid(), reason, true);
END;
$$;

CREATE OR REPLACE FUNCTION public.reactivate_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_active_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE public.user_suspensions
  SET is_active = false, lifted_at = now()
  WHERE user_suspensions.user_id = reactivate_user.user_id AND is_active = true;
END;
$$;

CREATE OR REPLACE FUNCTION public.send_broadcast_notification(title text, body text, category text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_category text;
BEGIN
  IF NOT public.is_active_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  v_category := CASE 
    WHEN category IN ('important', 'requests', 'cityUpdates') THEN category
    ELSE 'cityUpdates'
  END;

  INSERT INTO public.notifications (
    id,
    owner_id,
    title,
    body,
    category,
    destination,
    reference_id,
    is_read,
    created_at,
    updated_at
  )
  SELECT 
    gen_random_uuid(),
    p.id,
    title,
    body,
    v_category,
    'none',
    NULL,
    false,
    now(),
    now()
  FROM public.profiles p
  WHERE NOT EXISTS (
    SELECT 1 FROM public.user_suspensions s
    WHERE s.user_id = p.id AND s.is_active = true
  );

  -- Also store in admin_notifications history
  INSERT INTO public.admin_notifications (
    id,
    title,
    body,
    category,
    created_at,
    sender_id
  ) VALUES (
    gen_random_uuid()::text,
    title,
    body,
    v_category,
    now(),
    auth.uid()
  );
END;
$$;

-- 10. Timestamp Triggers
CREATE OR REPLACE FUNCTION public.update_admin_profiles_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS admin_profiles_updated_at ON public.admin_profiles;
CREATE TRIGGER admin_profiles_updated_at
  BEFORE UPDATE ON public.admin_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_admin_profiles_timestamp();

DROP TRIGGER IF EXISTS admin_reviews_updated_at ON public.admin_reviews;
CREATE TRIGGER admin_reviews_updated_at
  BEFORE UPDATE ON public.admin_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.update_admin_profiles_timestamp();

-- 11. Storage Buckets (required for file uploads)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('complaint-photos', 'complaint-photos', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('vendor-documents', 'vendor-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- 12. GRANT EXECUTE on Admin RPC Functions
-- PostgREST only exposes functions in its schema cache if the connecting role
-- (anon or authenticated) has EXECUTE permission. Without these grants, the
-- functions exist in PostgreSQL but are invisible to the REST API.

-- Revoke default public access first (security hardening)
REVOKE ALL ON FUNCTION public.get_complaint_stats() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_admin_stats() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_vendor_stats() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_user_stats() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_notification_stats() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_complaints_by_service() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_complaints_by_status() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_applications_by_status() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_daily_stats(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_monthly_report(integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_admin_pending_complaints(integer, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_admin_complaint_details(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_admin_vendor_applications(integer, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_admin_vendor_application_details(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_update_complaint_status(text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_update_vendor_status(text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.suspend_user(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reactivate_user(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.send_broadcast_notification(text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_active_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_super_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_admin_profiles_timestamp() FROM PUBLIC;

-- Grant EXECUTE to authenticated role only (admin users are authenticated)
GRANT EXECUTE ON FUNCTION public.get_complaint_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_vendor_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_notification_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_complaints_by_service() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_complaints_by_status() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_applications_by_status() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_daily_stats(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_monthly_report(integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_pending_complaints(integer, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_complaint_details(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_vendor_applications(integer, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_vendor_application_details(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_complaint_status(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_vendor_status(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.suspend_user(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reactivate_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_broadcast_notification(text, text, text) TO authenticated;

-- Helper functions need authenticated access for RLS policy evaluation
GRANT EXECUTE ON FUNCTION public.is_active_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

-- Notify PostgREST to reload its schema cache
NOTIFY pgrst, 'reload schema';
