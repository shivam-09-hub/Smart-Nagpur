# Smart Nagpur Supabase backend

This folder contains the database, Row-Level Security, Storage, and RPC contract
used by the Flutter client. The mobile app uses only the Supabase project URL and
publishable key. Never add a `service_role` key or database password to Flutter.

## Deploy Migrations

Apply the versioned SQL migrations to your Supabase project in numerical order via Dashboard SQL Editor or Supabase CLI:

1. [`migrations/202608170001_smart_nagpur_backend.sql`](migrations/202608170001_smart_nagpur_backend.sql) (Citizen schema, RPCs, Storage).
2. [`migrations/202608180001_smart_nagpur_admin.sql`](migrations/202608180001_smart_nagpur_admin.sql) (Admin schema, review queues, RPCs).
3. [`migrations/202608190001_smart_nagpur_staff.sql`](migrations/202608190001_smart_nagpur_staff.sql) (Staff profiles, task assignments, evidence bucket, Haversine distance calculator).
4. [`repair_and_fix_staff.sql`](repair_and_fix_staff.sql) (Token normalization & native staff provisioning RPC).

### Native Staff Provisioning (No Edge Function deployment blocker)
Staff accounts are provisioned securely via PostgreSQL stored procedure `admin_create_staff_account` with full GoTrue token normalization.

A publishable mobile key cannot apply database DDL. Deployment requires an
authorized Dashboard user or a locally authenticated/linked Supabase CLI; do not
work around this by placing a secret or service-role key in the app.

The migrations are safe to rerun. They create/backfill profiles, install triggers, create private storage buckets, configure RLS, and apply least-privilege grants.

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

## Storage Contracts

The migrations configure three private storage buckets:

| Bucket | Limit | MIME types | Description |
| --- | ---: | --- | :--- |
| `complaint-photos` | 10 MB | JPEG, PNG, WebP | Citizen grievance photos |
| `vendor-documents` | 10 MB | PDF, JPEG, PNG | Vendor identity & KYC documents |
| `complaint-evidence` | 10 MB | JPEG, PNG, WebP | Field staff resolution proof photos |

For both buckets, the object name is exactly:

```text
<auth-user-uuid>/<upload-group-uuid>/<file-uuid>.<extension>
```

Storage RLS enforces the owner UUID in the first path segment. Objects cannot be
updated in place. An owner may delete an unreferenced upload during rollback, but
cannot delete evidence after its metadata is attached to a submitted record. The
submit RPCs also validate the group UUID, file UUID, extension, bucket, MIME type,
byte size, Storage `owner_id`, and the stored system metadata before recording it.
Upload objects before calling the RPC. Database rows are atomic, but Storage is a
separate service; if the RPC fails, the client should delete that attempt's
uploaded objects.

## RPC contract

All JSON exposed to Flutter uses camelCase domain keys. SQL table/column names
remain snake_case.

### `submit_complaint(payload jsonb, attachments jsonb) -> jsonb`

`payload` is `ComplaintDraft.toJson()` without `photoPaths`:

```json
{
  "serviceType": "roads",
  "issue": "Pothole",
  "description": "Large pothole near the junction",
  "location": {
    "latitude": 21.1458,
    "longitude": 79.0882,
    "accuracy": 12.0,
    "address": "Civil Lines, Nagpur"
  },
  "contactPhone": "9876543210",
  "citizenAddress": "Dharampeth, Nagpur",
  "extraFields": {"ward": "12"}
}
```

`attachments` contains zero to five uploaded photo records:

```json
[
  {
    "bucket": "complaint-photos",
    "objectPath": "USER_UUID/GROUP_UUID/FILE_UUID.jpg",
    "originalName": "pothole.jpg",
    "contentType": "image/jpeg",
    "byteSize": 234567,
    "sortOrder": 0
  }
]
```

The RPC creates the complaint, normalized photo rows, initial timeline entry, and
notification in one database transaction. It generates the public reference,
timestamps, and `submitted` status. It returns one `ComplaintRemote`:

```json
{
  "id": "NAG-2026-000001",
  "serviceType": "roads",
  "issue": "Pothole",
  "description": "Large pothole near the junction",
  "photos": [
    {
      "bucket": "complaint-photos",
      "objectPath": "USER_UUID/GROUP_UUID/FILE_UUID.jpg",
      "originalName": "pothole.jpg",
      "contentType": "image/jpeg",
      "byteSize": 234567,
      "sortOrder": 0
    }
  ],
  "location": {
    "latitude": 21.1458,
    "longitude": 79.0882,
    "accuracy": 12.0,
    "address": "Civil Lines, Nagpur"
  },
  "contactPhone": "9876543210",
  "citizenAddress": "Dharampeth, Nagpur",
  "extraFields": {"ward": "12"},
  "createdAt": "2026-08-17T10:00:00+00:00",
  "updatedAt": "2026-08-17T10:00:00+00:00",
  "status": "submitted",
  "timeline": [
    {
      "title": "Submitted",
      "timestamp": "2026-08-17T10:00:00+00:00",
      "message": "Your civic report has been received.",
      "isCompleted": true
    }
  ],
  "isDemo": false
}
```

### `submit_vendor_application(payload jsonb, documents jsonb) -> jsonb`

`payload` is `VendorApplicationDraft.toJson()` without local `documents`. Exact
keys are:

```text
applicantName, mobile, email, residentialAddress, identityInformation,
businessName, businessType, category, description, productsServices,
registrationNumber, location, preferredZone, operatingDays, startTime, endTime,
durationType, outletType, acceptedDeclaration
```

`location` has the same four keys as a complaint location. `operatingDays` uses
English day names, times use `HH:mm`, `durationType` is `Temporary` or
`Permanent`, and `outletType` is `Stall`, `Cart`, `Shop`, or `Other`.

`documents` contains zero to twelve objects. The Flutter wizard determines which
documents are required for the applicant's answers; the RPC validates every
submitted document (including every `requirement: "required"` entry) and will not
accept metadata without a corresponding private Storage object:

```json
[
  {
    "type": "identity-proof",
    "label": "Identity Proof",
    "requirement": "required",
    "bucket": "vendor-documents",
    "objectPath": "USER_UUID/GROUP_UUID/FILE_UUID.pdf",
    "originalName": "identity.pdf",
    "contentType": "application/pdf",
    "byteSize": 345678,
    "sortOrder": 0
  }
]
```

The response is one `VendorRemote`, equivalent to `VendorApplication.toJson()`
except `details.documents` contains the metadata above instead of local `path`:

```json
{
  "id": "VN-2026-000001",
  "details": {
    "applicantName": "Aarav Kulkarni",
    "mobile": "9876543210",
    "email": "aarav@example.com",
    "residentialAddress": "Dharampeth, Nagpur",
    "identityInformation": "Identity details",
    "businessName": "Orange City Snacks",
    "businessType": "Street food cart",
    "category": "Food & Beverage",
    "description": "Fresh snacks and beverages",
    "productsServices": "Poha and tea",
    "registrationNumber": "",
    "location": {
      "latitude": 21.1458,
      "longitude": 79.0882,
      "accuracy": 12.0,
      "address": "Civil Lines, Nagpur"
    },
    "preferredZone": "Civil Lines",
    "operatingDays": ["Monday", "Tuesday"],
    "startTime": "08:00",
    "endTime": "18:00",
    "durationType": "Permanent",
    "outletType": "Cart",
    "documents": [],
    "acceptedDeclaration": true
  },
  "status": "submitted",
  "createdAt": "2026-08-17T10:00:00+00:00",
  "updatedAt": "2026-08-17T10:00:00+00:00",
  "timeline": [
    {
      "title": "Application submitted",
      "timestamp": "2026-08-17T10:00:00+00:00",
      "message": "Your vendor application has been received.",
      "isCompleted": true,
      "isCurrent": true
    }
  ],
  "isDemo": false
}
```

### `get_current_user_data() -> jsonb`

The RPC returns only the authenticated owner's data:

```json
{
  "profile": {
    "name": "Aarav Kulkarni",
    "phone": "9876543210",
    "email": "aarav@example.com",
    "address": "Dharampeth, Nagpur",
    "avatarPath": null
  },
  "complaints": [],
  "vendorApplications": [],
  "notifications": [
    {
      "id": "NOTIFICATION_UUID",
      "title": "Complaint submitted",
      "body": "NAG-2026-000001 has been received.",
      "category": "requests",
      "createdAt": "2026-08-17T10:00:00+00:00",
      "destination": "complaint",
      "referenceId": "NAG-2026-000001",
      "isRead": false,
      "isDemo": false
    }
  ]
}
```

`complaints` contains `ComplaintRemote` objects and `vendorApplications` contains
`VendorRemote` objects exactly as returned by the submit RPCs. Empty collections
are always `[]`; `profile` is `null` only if an administrator removed the row.

## Row contract

| Table | Primary/owner fields | Purpose |
| --- | --- | --- |
| `profiles` | `id = auth.users.id` | Citizen profile; email is Auth-derived |
| `complaints` | UUID `id`, public `public_id`, `owner_id` | Complaint parent and workflow status |
| `complaint_photos` | `complaint_id`, `owner_id` | Private Storage metadata, ordered |
| `complaint_timeline` | `complaint_id`, `owner_id` | Server-managed complaint events |
| `vendor_applications` | UUID `id`, public `public_id`, `owner_id` | Vendor form and workflow status |
| `vendor_documents` | `vendor_application_id`, `owner_id` | Private Storage metadata, ordered |
| `vendor_timeline` | `vendor_application_id`, `owner_id` | Server-managed vendor events |
| `notifications` | UUID `id`, `owner_id` | Domain notification; citizen edits only `is_read` |

The SQL migration is the authoritative column-level contract. Foreign keys pair
each child ID with the same `owner_id`, preventing cross-owner child attachment.

Exact physical columns (all names are snake_case):

```text
profiles(
  id uuid PK/FK auth.users, name text, phone text, email text, address text,
  avatar_path text?, created_at timestamptz, updated_at timestamptz
)

complaints(
  id uuid PK, public_id text UNIQUE, owner_id uuid FK auth.users,
  service_type text, issue text, description text, latitude float8,
  longitude float8, accuracy float8, location_address text,
  contact_phone text, citizen_address text?, extra_fields jsonb, status text,
  created_at timestamptz, updated_at timestamptz
)

complaint_photos(
  id uuid PK, complaint_id uuid, owner_id uuid, bucket_id text,
  object_path text UNIQUE, original_name text, content_type text,
  byte_size bigint, sort_order smallint, created_at timestamptz
)

complaint_timeline(
  id uuid PK, complaint_id uuid, owner_id uuid, title text,
  occurred_at timestamptz, message text?, is_completed boolean,
  created_at timestamptz
)

vendor_applications(
  id uuid PK, public_id text UNIQUE, owner_id uuid FK auth.users,
  applicant_name text, mobile text, email text, residential_address text,
  identity_information text, business_name text, business_type text,
  category text, description text, products_services text,
  registration_number text, latitude float8, longitude float8,
  accuracy float8, location_address text, preferred_zone text,
  operating_days text[], start_time time, end_time time, duration_type text,
  outlet_type text, accepted_declaration boolean, status text,
  created_at timestamptz, updated_at timestamptz
)

vendor_documents(
  id uuid PK, vendor_application_id uuid, owner_id uuid, document_type text,
  label text, requirement text, bucket_id text, object_path text UNIQUE,
  original_name text, content_type text, byte_size bigint,
  sort_order smallint, created_at timestamptz
)

vendor_timeline(
  id uuid PK, vendor_application_id uuid, owner_id uuid, title text,
  occurred_at timestamptz?, message text?, is_completed boolean,
  is_current boolean, created_at timestamptz
)

notifications(
  id uuid PK, owner_id uuid FK auth.users, title text, body text,
  category text, destination text, reference_id text?, is_read boolean,
  created_at timestamptz, updated_at timestamptz
)
```
