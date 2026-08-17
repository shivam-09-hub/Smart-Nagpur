# Smart Nagpur

Unified civic services, municipal governance, and on-ground field resolution platform for Nagpur, backed by Supabase.

The platform provides three specialized mobile applications built on a shared domain, gateway, and database architecture:
1. **Citizen App (`lib/main.dart` / Flavor: `citizen`)**: Service discovery, grievance reporting with GPS & camera, street vendor permitting, milestone tracking, news, and notifications.
2. **Municipal Admin App (`lib/admin_main.dart` / Flavor: `admin`)**: Executive dashboard, complaint triage, vendor permit reviews, staff provisioning, staff assignment, and broadcast notifications.
3. **Field Staff App (`lib/staff_main.dart` / Flavor: `staff`)**: On-duty shift status toggle, real-time task ingestion, on-site resolution verification, GPS navigation, and before/after proof submissions.

All data is stored in PostgreSQL and files in private Supabase Storage buckets (`complaint-photos`, `vendor-documents`, `complaint-evidence`).

---

## Key Features & Highlights

- **Multi-Tier Interconnected Lifecycle**:
  - Citizen lodges a complaint with GPS & photos.
  - Admin triages and assigns to field technician in real-time.
  - Staff receives task on-device, navigates with GPS, captures before/after photo proof, and submits completion notes.
  - Admin verifies proof and approves resolution.
  - Citizen app instantly updates with real-time status and timeline milestones.
- **Accurate Real-World Timestamps**: Universal device-local timezone formatting (`.toLocal()`) across all domain models and screens in IST.
- **Native Staff Provisioning**: Direct, secure PostgreSQL RPC (`admin_create_staff_account`) with automated GoTrue token normalization.
- **Production Quality**: `flutter analyze` has **0 issues** and all **119 automated tests** pass.

---

## Required Supabase Setup

The configured project is `hcpcycfvupjuklhcaxzg`. Complete these steps in the Supabase Dashboard SQL Editor:

1. Run [`202608170001_smart_nagpur_backend.sql`](supabase/migrations/202608170001_smart_nagpur_backend.sql) (Citizen schema, tables & storage).
2. Run [`202608180001_smart_nagpur_admin.sql`](supabase/migrations/202608180001_smart_nagpur_admin.sql) (Admin schema, analytics & review RPCs).
3. Run [`202608190001_smart_nagpur_staff.sql`](supabase/migrations/202608190001_smart_nagpur_staff.sql) (Staff schema, evidence bucket & assignment RPCs).
4. Run [`repair_and_fix_staff.sql`](supabase/repair_and_fix_staff.sql) to normalize auth tokens and ensure clean staff provisioning.
5. In **Authentication -> URL Configuration -> Redirect URLs**, add:
   ```text
   com.smartnagpur.citizen://login-callback/
   com.smartnagpur.admin://login-callback/
   com.smartnagpur.staff://login-callback/
   ```

---

## Running Locally

```powershell
# 1. Run Citizen App
flutter run --flavor citizen -t lib/main.dart

# 2. Run Admin App
flutter run --flavor admin -t lib/admin_main.dart

# 3. Run Field Staff App
flutter run --flavor staff -t lib/staff_main.dart
```

---

## Validate & Build

```powershell
# Run Static Analysis & Tests
flutter analyze
flutter test

# Build Release APKs per Flavor
flutter build apk --release --flavor citizen -t lib/main.dart
flutter build apk --release --flavor admin -t lib/admin_main.dart
flutter build apk --release --flavor staff -t lib/staff_main.dart
```

Generated APKs are located at `build/app/outputs/flutter-apk/`:
- `app-citizen-release.apk`
- `app-admin-release.apk`
- `app-staff-release.apk`

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
