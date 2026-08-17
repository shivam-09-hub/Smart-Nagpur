# Smart Nagpur

Unified civic services, municipal governance, and on-ground field resolution platform for Nagpur, backed by Supabase.

The platform provides three specialized mobile applications built on a shared domain, gateway, and database architecture:
1. **Citizen App (`lib/main.dart`)**: Service discovery, grievance reporting with GPS & camera, street vendor permitting, milestone tracking, news, and notifications.
2. **Municipal Admin App (`lib/admin_main.dart`)**: Executive dashboard, complaint triage, vendor permit reviews, user account management, staff provisioning, and broadcast notifications.
3. **Field Staff App (`lib/staff_main.dart`)**: On-duty status toggle, task management, on-site resolution verification, and before/after proof submissions.

Signed-in account data is stored in PostgreSQL and files in private Supabase Storage buckets (`complaint-photos`, `vendor-documents`, `complaint-evidence`).

---

## Required Supabase Setup

The configured project is `hcpcycfvupjuklhcaxzg`. Complete these steps in the Supabase Dashboard SQL Editor:

1. Run [`202608170001_smart_nagpur_backend.sql`](supabase/migrations/202608170001_smart_nagpur_backend.sql) (Citizen schema & storage).
2. Run [`202608180001_smart_nagpur_admin.sql`](supabase/migrations/202608180001_smart_nagpur_admin.sql) (Admin schema & RPCs).
3. Run [`202608190001_smart_nagpur_staff.sql`](supabase/migrations/202608190001_smart_nagpur_staff.sql) (Staff schema, evidence bucket, Haversine RPC).
4. Run [`schema_contract.sql`](supabase/tests/schema_contract.sql) to validate schema health.
5. Deploy Edge Function:
   ```bash
   supabase functions deploy admin-create-staff --no-verify-jwt
   ```
6. In **Authentication -> URL Configuration -> Redirect URLs**, add:
   ```text
   com.smartnagpur.citizen://login-callback/
   com.smartnagpur.admin://login-callback/
   com.smartnagpur.staff://login-callback/
   ```

---

## Run Locally

```powershell
# 1. Run Citizen App
flutter run -t lib/main.dart

# 2. Run Admin App
flutter run -t lib/admin_main.dart

# 3. Run Field Staff App
flutter run -t lib/staff_main.dart
```

---

## Validate & Build

```powershell
# Run Static Analysis & Tests
flutter analyze --no-pub
flutter test --no-pub

# Build Split APKs (Optimized per ABI)
flutter build apk --release --split-per-abi -t lib/main.dart
flutter build apk --release --split-per-abi -t lib/admin_main.dart
flutter build apk --release --split-per-abi -t lib/staff_main.dart
```

Generated APKs are located at `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (Modern 64-bit phones)
- `app-armeabi-v7a-release.apk` (32-bit legacy devices)
- `app-universal-release.apk` (Universal package)

---

## Documentation Links

- [System Architecture](ARCHITECTURE.md)
- [Product Requirements](PRD.md)
- [Implementation Phases & Roadmap](PHASES.md)
- [Build Flavors & Release Guide](BUILD_FLAVORS_GUIDE.md)
- [Design System](DESIGN.md)
- [Architecture Rules](RULES.md)
- [Supabase Setup Guide](supabase/README.md)
- [Admin App Summary](ADMIN_README.md)
- [Field Staff App Summary](STAFF_README.md)
- [Memory & State History](MEMORY.md)


