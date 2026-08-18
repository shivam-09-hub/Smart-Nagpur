# Smart Nagpur Supabase Backend

This folder contains the database, Row-Level Security, Storage, and RPC contracts used by the Flutter client. The mobile apps use only the Supabase project URL and publishable key. Never add a `service_role` key or database password to Flutter.

---

## 1. Deploy Migrations

Apply the versioned SQL migrations to your Supabase project in numerical order via Dashboard SQL Editor or Supabase CLI:

1. [`migrations/202608170001_smart_nagpur_backend.sql`](migrations/202608170001_smart_nagpur_backend.sql) (Citizen schema, RPCs, Storage).
2. [`migrations/202608180001_smart_nagpur_admin.sql`](migrations/202608180001_smart_nagpur_admin.sql) (Admin schema, review queues, RPCs).
3. [`migrations/202608190001_smart_nagpur_staff.sql`](migrations/202608190001_smart_nagpur_staff.sql) (Staff profiles, task assignments, evidence bucket, Haversine distance calculator, operations dashboard).
4. [`repair_and_fix_staff.sql`](repair_and_fix_staff.sql) (Token normalization & native staff provisioning RPC).

### Native Staff Provisioning
Staff accounts are provisioned securely via PostgreSQL stored procedure `admin_create_staff_account` with full GoTrue token normalization.

Enable Email/Password authentication in the Dashboard and keep email confirmation enabled. In **Authentication -> URL Configuration -> Redirect URLs**, allow these exact Android deep links (including trailing slashes):

```text
com.smartnagpur.citizen://login-callback/
com.smartnagpur.admin://login-callback/
com.smartnagpur.staff://login-callback/
```

After deployment, run the schema tests in the SQL Editor:
- [`tests/schema_contract.sql`](tests/schema_contract.sql)
- [`tests/202608190001_smart_nagpur_staff_test.sql`](tests/202608190001_smart_nagpur_staff_test.sql)

---

## 2. Storage Contracts

The migrations configure three private storage buckets:

| Bucket | Limit | MIME types | Description |
| :--- | ---: | :--- | :--- |
| `complaint-photos` | 10 MB | JPEG, PNG, WebP | Citizen grievance photos |
| `vendor-documents` | 10 MB | PDF, JPEG, PNG | Vendor identity & KYC documents |
| `complaint-evidence` | 10 MB | JPEG, PNG, WebP, PDF | Field staff resolution photos & inspection reports |

### Path Structure:
- **Citizen / Vendor:** `<auth-user-uuid>/<upload-group-uuid>/<file-uuid>.<extension>`
- **Staff Evidence:** `<staff_id>/<complaint_id>/<assignment_id>/<file-uuid>.<extension>`

Storage RLS enforces owner/staff path prefix constraints and short-lived signed URLs (5 minutes) for private retrieval.

---

## 3. Relational Schema Summary (15 Tables)

1. `profiles`: Citizen demographic records linked 1:1 with `auth.users.id`.
2. `complaints`: Citizen grievances with location coordinates, service category, and workflow status.
3. `complaint_photos`: Metadata for citizen-uploaded grievance photos.
4. `complaint_timeline`: Server-managed milestone events for complaints.
5. `vendor_applications`: Commercial street vendor permits, business classification, zone allocation, operating hours.
6. `vendor_documents`: Metadata for vendor KYC and site documentation.
7. `vendor_timeline`: Server-managed milestone events for vendor permits.
8. `notifications`: Domain notification inbox across citizen, admin, and staff accounts.
9. `admin_profiles`: Administrator accounts with role-based access control (6 roles).
10. `admin_notifications`: System-wide audit log for administrative broadcasts.
11. `admin_reviews`: Audit records of official reviews on complaints and applications.
12. `user_suspensions`: Account moderation and suspension history.
13. `staff_profiles`: Field technicians, department supervisors, and officers.
14. `complaint_assignments`: Assignment and dispatch audit history tracking task progress.
15. `complaint_evidence`: Resolution proof records containing before/after photos, GPS metrics, and inspection PDFs.
