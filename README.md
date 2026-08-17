# Smart Nagpur

Citizen-facing Android Flutter application backed by Supabase. The app supports
email authentication, news and service discovery, complaint reporting, GPS,
private photo uploads, vendor applications and documents, request tracking,
notifications, search, and profile/settings flows.

Signed-in account data is designed to be stored in Supabase Postgres and user
files in private Supabase Storage buckets. The Flutter integration is complete,
but the remote project must be initialized with the checked-in SQL migration
before cloud account flows and persistence work end to end. The project is not
connected to an official municipal case-management system, so submissions are
not official municipal complaints or permits.

## Required Supabase setup

The configured project is `hcpcycfvupjuklhcaxzg`. Complete these one-time steps
before creating an account:

1. Open the project in the Supabase Dashboard and select **SQL Editor**.
2. Paste and run
   [`202608170001_smart_nagpur_backend.sql`](supabase/migrations/202608170001_smart_nagpur_backend.sql).
   It creates the tables, transactional submission functions, Row-Level
   Security policies, Auth profile trigger, and private `complaint-photos` and
   `vendor-documents` buckets.
3. Paste and run [`schema_contract.sql`](supabase/tests/schema_contract.sql).
   A successful validation returns `Smart Nagpur schema contract: OK`.
4. In **Authentication -> URL Configuration -> Redirect URLs**, add this exact
   callback, including the trailing slash:

   ```text
   com.smartnagpur.citizen://login-callback/
   ```

   The callback is used for both email confirmation and password recovery.

A publishable key cannot create database tables, policies, functions, or
buckets. Apply the migration from an authorized Dashboard session; do not put a
database password, secret key, or service-role key in the mobile app. See the
[complete Supabase setup guide](supabase/README.md) for the database, Storage,
RPC, and ownership contracts.

The mobile app contains only the supplied publishable client key, which is the
client-safe credential intended to be distributed with the app. Access to user
data is enforced by authenticated sessions, Row-Level Security, restricted
grants, and owner-scoped RPCs. Configuration can be overridden at build time:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Email/password authentication and email confirmation are used because phone
authentication is disabled in the configured Supabase project. Use the project
root URL (`https://PROJECT.supabase.co`), not the `/rest/v1/` endpoint; the app
also normalizes a pasted REST endpoint to the project root.

## Run

```powershell
flutter pub get
flutter run
```

The login screen also includes an explicit demo mode. Demo mode never sends its
sample profile, requests, or files to Supabase.

Onboarding and locale preferences plus the most recently loaded, owner-scoped
signed-in data are cached in app-private storage. If Supabase is
temporarily unavailable, the app can show that matching user's cached reads and
an offline state. Profile changes, complaint submissions, vendor applications,
and notification writes still require a live Supabase connection; cloud writes
are not queued offline. Signing out clears protected cached data, and the app
never treats a saved local flag as a Supabase session.

## Validate

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.
The latest Supabase integration checkpoint completed with a clean analyzer, all
25 tests passing, and a successful debug APK build.

## Architecture

The app uses feature-based presentation modules, shared domain models,
app-owned Auth/data/file gateway interfaces, Supabase adapters, and a JSON local
cache. See [ARCHITECTURE.md](ARCHITECTURE.md), [DESIGN.md](DESIGN.md),
[MEMORY.md](MEMORY.md), and the [Supabase setup guide](supabase/README.md) for
implementation details.
