-- ============================================================
-- SMART NAGPUR — HOTFIX: Admin RPCs + Storage Buckets
-- ============================================================
-- Run this ONCE in Supabase Dashboard → SQL Editor
-- This fixes 10 broken admin RPCs and 2 missing storage buckets
-- ============================================================

-- 1. Create Storage Buckets (complaint photos & vendor documents)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('complaint-photos', 'complaint-photos', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('vendor-documents', 'vendor-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- 2. Drop old functions to avoid return type conflicts
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

-- 3. Grant EXECUTE to authenticated role (admin users are authenticated)
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
GRANT EXECUTE ON FUNCTION public.is_active_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

-- 4. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
