# Architecture

Smart Nagpur is one Flutter Android application for both citizen and vendor
workflows. It uses null-safe Dart and a feature-based structure.

## Layers

- `lib/domain`: serializable entities and drafts with no persistence concerns.
- `lib/data`: app-owned Auth/data/file contracts, Supabase adapters, demo data,
  and JSON local cache storage.
- `lib/state`: `AppController`, the application-level coordinator and injectable
  boundary between presentation and repositories/device capabilities.
- `lib/core`: theme, localization, reusable widgets, and replaceable GPS/media/
  document services.
- `lib/features`: route-level presentation and feature-specific widgets.

The signed-in presentation flow is:

`Widget -> AppController -> Auth/RemoteDataGateway -> Supabase Auth/Postgres/Storage`

`LocalAppRepository` stores onboarding, locale, and a user-ID-scoped cache. A
persisted local boolean is never trusted as a cloud authentication session;
Supabase Auth is the source of truth. Gateway interfaces keep Supabase SDK types
out of widgets and domain models.

`Supabase.initialize` receives the project root URL and a publishable key. That
client key is intentionally distributable and is not an administrative
credential; a secret/service-role key or database password must never be added
to Flutter. The checked-in SQL migration is deployed separately by an
authorized Supabase Dashboard user and is not executed by the mobile client.

## Navigation

`SmartNagpurApp` owns named-route generation. `AppShell` owns the persistent
Home, Services, My Requests, Notifications, and Profile destinations. Dynamic
news, service, and request routes are resolved centrally.

## Persistence, files, and demo safety

Profiles, complaints, applications, timelines, and notifications are owner-
scoped Postgres records. Complaint photos and vendor documents are validated,
uploaded to private buckets under an authenticated user prefix, and downloaded
into an app-private cache when needed by existing file widgets. Failed record
creation rolls back newly uploaded objects where possible.

The SQL backend uses transactional submission RPCs so the client cannot assign
official workflow statuses or timeline decisions. Row-Level Security restricts
every citizen read/write to `auth.uid()`. Demo mode is an explicit, local-only
branch and never calls Supabase.

The local cache is also scoped to the current Supabase user ID. It supports
previously loaded reads during a temporary backend outage but is not an offline
write queue: profile updates, submissions, uploads, and notification changes
must reach Supabase. Protected cached data is discarded on sign-out or user-ID
mismatch. Demo records remain local and are never sent or synchronized into a
cloud account.

Private Storage objects use
`<auth.uid()>/<upload-group UUID>/<file UUID>.<extension>` paths. Complaint
images accept JPEG, PNG, or WebP; vendor documents accept PDF, JPEG, or PNG;
each file is limited to 10 MiB. Database grants, Storage policies, and RPC
validation all enforce the same ownership and file contract.

## Authentication callbacks

Email confirmation and password recovery return through the Android deep link
`com.smartnagpur.citizen://login-callback/`. The Android manifest registers this
scheme/host and Supabase must allow the exact URL, including its trailing slash,
under **Authentication -> URL Configuration -> Redirect URLs**.

## Backend deployment boundary

The schema, Row-Level Security policies, Storage buckets, profile trigger, and
RPCs live in
[`supabase/migrations/202608170001_smart_nagpur_backend.sql`](supabase/migrations/202608170001_smart_nagpur_backend.sql).
They must be applied from the Supabase SQL Editor (or an authenticated, linked
CLI) before cloud flows work. The post-deployment contract check is
[`supabase/tests/schema_contract.sql`](supabase/tests/schema_contract.sql). See
the [Supabase backend guide](supabase/README.md) for the full procedure.

## Location and maps

`DeviceLocationService` uses `geolocator` for foreground GPS coordinates and
accuracy. No background location is requested. Because no approved map provider
or API key was supplied, `DevelopmentMap` is a configuration-free adjustable-pin
placeholder. It can be replaced behind the presentation boundary when a provider
is approved.

## State management

Flutter's `ChangeNotifier` and `ListenableBuilder` coordinate application state.
Feature dependencies and gateway interfaces are injectable, so tests use
deterministic in-memory fakes without initializing Supabase or device plugins.

## Admin Application (`lib/admin_main.dart`)

The Smart Nagpur Admin application is a separate Flutter app built from the same codebase using build flavors. It shares domain models and data gateways with the citizen app but has its own entry point, screens, and state management.

### Admin Architecture Overview

- **Entry Point**: `lib/admin_main.dart` - Initializes Supabase and AdminController
- **State Management**: `AdminController` - Single source of truth for admin app state
- **Screens**: Located in `lib/features/admin/presentation/`
- **Data Layer**: 
  - `AdminAuthGateway` - Authentication and admin profile management
  - `AdminDataGateway` - Complaint, vendor, notification, and user data operations
  - Supabase adapters: `SupabaseAdminAuthGateway`, `SupabaseAdminDataGateway`

### Admin Permissions & Roles

Admin users are assigned roles that control access:

- **SuperAdmin**: Full system access
- **ComplaintReviewer**: Review and manage complaints
- **VendorReviewer**: Approve/reject vendor applications  
- **NotificationManager**: Send notifications to users
- **ReportViewer**: View analytics and reports
- **UserManager**: Manage and suspend user accounts

Row-Level Security policies on `admin_profiles`, `admin_reviews`, and `admin_notifications` tables enforce role-based access.

### Admin Database Schema

New tables added via `supabase/migrations/202608180001_smart_nagpur_admin.sql`:

- `admin_profiles` - Admin user accounts with role and permissions
- `admin_notifications` - System-wide notifications for admins
- `admin_reviews` - Assessments and reviews of complaints/applications
- `user_suspensions` - Track suspended user accounts

### Admin Screens

1. **Login Screen** - Email/password authentication
2. **Dashboard** - Statistics, metrics, quick actions
3. **Complaints Screen** - List of pending complaints
4. **Complaint Detail** - Full complaint info, timeline, status updates
5. **Vendors Screen** - List of pending vendor applications
6. **Notifications Screen** - Send broadcast or targeted notifications
7. **Users Screen** - Manage user accounts, suspensions

### Admin Data Flow

The admin app follows the same layered architecture as the citizen app:

```
AdminScreen → AdminController → AdminDataGateway → Supabase (RPC/REST API)
```

- `AdminController` coordinates state changes and data loading
- `AdminAuthGateway` handles admin login/logout and profile management
- `AdminDataGateway` provides methods for complaints, applications, notifications, and users
- Supabase adapters execute queries and RPCs
- Row-Level Security enforces authorization at the database layer

### Admin Authentication Flow

1. Admin enters email/password on login screen
2. `AdminAuthGateway.loginAdmin()` authenticates with Supabase Auth
3. Upon successful auth, admin profile is fetched from `admin_profiles` table
4. Admin role is verified and stored in `AdminController`
5. User is navigated to admin dashboard
6. Session is maintained by Supabase Auth token

### Admin RPC Functions

Special database functions for admin operations:

- `get_admin_stats()` - Dashboard statistics
- `get_complaint_stats()` - Complaint metrics
- `get_vendor_stats()` - Vendor application metrics
- `get_user_stats()` - User account statistics
- `get_daily_stats(days)` - Daily trends
- `get_monthly_report(month, year)` - Monthly report
- `suspend_user(user_id, reason)` - Suspend user account
- `reactivate_user(user_id)` - Reactivate suspended user
- `send_broadcast_notification(...)` - Send to all users
- `add_complaint_timeline(complaint_id, entry)` - Add timeline entry

### Build Flavors

Two build flavors exist to support separate APKs:

- **citizen** - `com.smartnagpur.citizen` - Citizen application
- **admin** - `com.smartnagpur.admin` - Admin application

See [BUILD_FLAVORS_GUIDE.md](BUILD_FLAVORS_GUIDE.md) for setup instructions and build commands.

### Admin Deep Link

Admin authentication callback uses the deep link: `com.smartnagpur.admin://login-callback/`

This must be registered in Supabase URL Configuration and in the Android manifest.
