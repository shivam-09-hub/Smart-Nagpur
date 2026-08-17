-- =============================================================================
-- SMART NAGPUR — Link Verified Field Staff Account (ramesh.staff@gmail.com)
-- =============================================================================

-- 1. Remove old staff profile row with employee_id = 'NMC-RD-101'
DELETE FROM public.complaint_assignments WHERE staff_id IN (SELECT id FROM public.staff_profiles WHERE employee_id = 'NMC-RD-101' OR email = 'ramesh.staff@gmail.com');
DELETE FROM public.complaint_evidence WHERE staff_id IN (SELECT id FROM public.staff_profiles WHERE employee_id = 'NMC-RD-101' OR email = 'ramesh.staff@gmail.com');
DELETE FROM public.staff_profiles WHERE employee_id = 'NMC-RD-101' OR email = 'ramesh.staff@gmail.com';

-- 2. Confirm email in auth.users
UPDATE auth.users 
SET email_confirmed_at = now() 
WHERE email = 'ramesh.staff@gmail.com';

-- 3. Insert fresh linked staff profile
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
  is_on_duty
) VALUES (
  '2f5d5f09-3a13-4ef5-aa14-f569ad138a69'::uuid,
  'Ramesh Sharma',
  '+919876500001',
  'ramesh.staff@gmail.com',
  'NMC-RD-101',
  'ROAD',
  'FIELD_WORKER',
  'Dharampeth',
  'Ward 12',
  true,
  true
)
ON CONFLICT (id) DO UPDATE 
SET is_active = true, is_on_duty = true;
