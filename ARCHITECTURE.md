# System Architecture & Technical Specification — Smart Nagpur

This document outlines the complete architectural design, data flow, component boundaries, technical stack, and security model of the **Smart Nagpur** platform.

---

## 1. Technical Stack Overview

| Layer / Subsystem | Technology / Package | Role & Responsibility |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK `^3.11.5`) | Cross-platform UI toolkit targeting Android. |
| **Backend & Database** | Supabase (PostgreSQL 15+) | Managed database, relational schemas, RPCs, Auth, and Storage. |
| **Authentication** | Supabase Auth | Email/Password auth, session management, password recovery deep links. |
| **File Storage** | Supabase Storage | Private buckets for complaint photos and vendor documentation. |
| **Location Services** | `geolocator: ^14.0.3` | Foreground GPS coordinate extraction and accuracy scoring. |
| **Media & File Capture**| `image_picker: ^1.2.3`, `file_picker: ^12.0.0` | Camera capture, photo gallery selection, PDF document picking. |
| **Local Persistence** | `path_provider: ^2.1.6` + JSON Store | App-private cache for preferences, locale, and user-scoped offline reads. |
| **Localization & I18n** | `flutter_localizations`, `intl: ^0.20.2` | Bilingual translation engine supporting English and Marathi (`mr`). |
| **State Management** | Flutter `ChangeNotifier` + `ListenableBuilder` | Lightweight, reactive, decoupled application state coordination. |
| **Code Quality & Lints**| `flutter_lints: ^6.0.0` | Strict static analysis, null safety, and code convention enforcement. |

---

## 2. Layered Architecture (Clean Architecture Pattern)

The codebase is organized into strict, decoupled layers located under `lib/`:

```
lib/
├── core/         # Cross-cutting concerns, theme tokens, localization, device services
├── domain/       # Pure business entities, drafts, enums, models (zero UI / DB dependencies)
├── data/         # Gateways, Supabase adapters, local JSON cache, repositories, demo data
├── state/        # State controllers (AppController, AdminController)
└── features/     # Feature-driven UI screens, presentation widgets, and route modules
```

```
┌───────────────────────────────────────────────────────────────┐
│                    Presentation Layer                         │
│   (Features: Auth, Home, Services, Complaints, Vendor, etc.)  │
└──────────────────────────────┬────────────────────────────────┘
                               │ (calls actions / listens to state)
                               ▼
┌───────────────────────────────────────────────────────────────┐
│                      State Layer                              │
│       (AppController, AdminController via ChangeNotifier)     │
└──────────────────────────────┬────────────────────────────────┘
                               │ (calls abstract gateway interfaces)
                               ▼
┌───────────────────────────────────────────────────────────────┐
│                      Data Gateway Layer                       │
│    (AuthGateway, RemoteDataGateway, AdminDataGateway, etc.)   │
└──────────────┬───────────────────────────────┬────────────────┘
               │ (implements)                  │ (implements)
               ▼                               ▼
┌──────────────────────────────┐ ┌──────────────────────────────┐
│       Supabase Adapters      │ │      Local Cache / Repo      │
│  (Supabase Client, PostgREST │ │ (JsonFileStore, AppStateData │
│    Storage, RPC Endpoints)   │ │   Scoped to cachedUserId)    │
└──────────────────────────────┘ └──────────────────────────────┘
```

### 2.1. Layer Responsibilities

1. **`lib/domain`**:
   - Contains pure Dart domain entities (`ComplaintRecord`, `VendorApplication`, `UserProfile`, `AdminProfile`, `AdminStats`, `AdminReview`, `StaffProfile`, `AppNotification`, `NewsItem`, `ProblemLocation`, `ServiceDefinition`).
   - Immutable data models equipped with `toJson()`, `fromJson()`, and `copyWith()` methods.
   - Completely agnostic of Flutter UI libraries and backend SDKs.

2. **`lib/data`**:
   - **`gateways/`**: Abstract interfaces (`AuthGateway`, `RemoteDataGateway`, `RemoteFileGateway`, `AdminAuthGateway`, `AdminDataGateway`, `StaffAuthGateway`, `StaffDataGateway`). This abstraction ensures that the UI and state layers never directly depend on Supabase SDK types, allowing instant mocking for unit/widget tests.
   - **`adapters/` & `supabase/`**: Concrete implementations (`SupabaseAuthGateway`, `SupabaseRemoteDataGateway`, `SupabaseFileGateway`, `SupabaseAdminAuthGateway`, `SupabaseAdminDataGateway`, `SupabaseStaffAuthGateway`, `SupabaseStaffDataGateway`) converting PostgREST JSON responses into typed domain entities.
   - **`local/` & `repositories/`**: `LocalAppRepository` backed by `JsonFileStore` managing cached state, onboarding flags, and locale.
   - **`demo/`**: `DemoData` provider supplying offline mock entities when operating in Demo Mode.

3. **`lib/state`**:
   - `AppController`: Coordinates citizen app lifecycle, authentication state changes, data refreshes, offline state detection, and complaint/vendor submission orchestration.
   - `AdminController`: Coordinates administrator authentication, permission validation, dashboard statistics loading, complaint/application triage, user suspension, staff provisioning, and notification broadcasting.
   - `StaffController`: Coordinates field staff authentication, shift duty status toggle, and task loading.

4. **`lib/core`**:
   - `theme/`: Centralized design system (`AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTypography`, `AppIcons`, `AppTheme`, `ServiceTheme`).
   - `localization/`: `AppStrings` providing localized string catalogs for English and Marathi.
   - `services/`: Device capability abstraction contracts (`LocationService`, `MediaPickerService`, `DocumentPickerService`, `PrivateFileStore`) with replaceable production and mock implementations.
   - `config/`: `SupabaseConfig` handling environment variables, URL normalization, and publishable key format validation.
   - `widgets/`: Reusable, atomic UI components (custom text fields, buttons, status badges, timeline nodes, state views, photo galleries).

5. **`lib/features`**:
   - Feature-partitioned modules containing screens, presentation widgets, and route helpers:
     - `bootstrap/` (Splash, Onboarding)
     - `auth/` (Login, Register, Forgot Password, Verification, Password Recovery)
     - `shell/` (AppShell bottom navigation container)
     - `home/` (Citizen dashboard, quick action grid, recent updates)
     - `services/` (10 service catalog and service detail pages)
     - `complaints/` (Complaint submission wizard, photo picker, GPS map pin, review)
     - `vendor/` (Vendor hub, 4-step registration wizard, zone map, document upload, renewal)
     - `requests/` (My Requests unified tracking, milestone timeline details)
     - `notifications/` (Notification list, category filtering)
     - `news/` (City news feed, news detail)
     - `search/` (Global search across services and news)
     - `profile/` (Profile edit, saved locations, language, privacy, terms, help)
     - `admin/` (Admin login, dashboard, complaints triage, vendor reviews, user management, notifications)
     - `staff/` (Staff login, dashboard, duty toggle, task shell, profile)

---

## 3. Multi-Application Architecture

The repository supports three distinct application binaries built from a unified codebase:

```
Smart Nagpur Unified Codebase
  ├── Citizen Application -> Entry: lib/main.dart
  ├── Admin Application   -> Entry: lib/admin_main.dart
  └── Staff Application   -> Entry: lib/staff_main.dart
```

### 3.1. Citizen Application
- **Entry Point:** `lib/main.dart`
- **Target Audience:** Citizens of Nagpur & Commercial Vendors.
- **Deep Link:** `com.smartnagpur.citizen://login-callback/`
- **Run/Build Command:**
  ```powershell
  flutter run -t lib/main.dart
  flutter build apk --release --split-per-abi -t lib/main.dart
  ```

### 3.2. Municipal Admin Application
- **Entry Point:** `lib/admin_main.dart`
- **Target Audience:** Municipal Officers, Ward Reviewers, and Super Administrators.
- **Deep Link:** `com.smartnagpur.admin://login-callback/`
- **Run/Build Command:**
  ```powershell
  flutter run -t lib/admin_main.dart
  flutter build apk --release --split-per-abi -t lib/admin_main.dart
  ```

### 3.3. Field Staff Application
- **Entry Point:** `lib/staff_main.dart`
- **Target Audience:** Field Workers, Maintenance Technicians, and Department Supervisors.
- **Deep Link:** `com.smartnagpur.staff://login-callback/`
- **Run/Build Command:**
  ```powershell
  flutter run -t lib/staff_main.dart
  flutter build apk --release --split-per-abi -t lib/staff_main.dart
  ```

---

## 4. Backend Architecture & Supabase Integration

The cloud backend is powered by Supabase with all database definitions checked into version control under `supabase/migrations/`.

### 4.1. PostgreSQL Schema Design (15 Tables)
1. **`profiles`**: Stores citizen demographic records linked 1:1 with `auth.users.id`.
2. **`complaints`**: Citizen grievances with service category, coordinates, address, photo URLs, status enum, contact phone, and assignment foreign keys.
3. **`complaint_photos`**: Metadata for citizen-uploaded grievance photos.
4. **`complaint_timeline`**: Citizen-facing milestone timeline for grievances.
5. **`vendor_applications`**: Commercial street vendor permits, business classification, zone allocation, operating hours, and document URLs.
6. **`vendor_documents`**: Metadata for vendor identity and vending location documents.
7. **`vendor_timeline`**: Vendor permit lifecycle timeline.
8. **`notifications`**: Personalized and broadcast notices across citizen, admin, and staff accounts.
9. **`admin_profiles`**: Administrator accounts storing assigned role (`superAdmin`, `complaintReviewer`, `vendorReviewer`, `reportViewer`, `notificationManager`, `userManager`), phone, and activation state.
10. **`admin_notifications`**: Audit log for administrative notifications and system actions.
11. **`admin_reviews`**: Audit records of official administrative reviews, notes, and ratings on complaints and applications.
12. **`user_suspensions`**: Account lock records tracking suspended users, reasons, and timestamps.
13. **`staff_profiles`**: Municipal field staff accounts storing department (`ROAD`, `WASTE`, `WATER`, `VENDOR`, `GENERAL`), role (`FIELD_WORKER`, `SUPERVISOR`, `OFFICER`), zone, employee ID, and duty status.
14. **`complaint_assignments`**: Immutable assignment and reassignment audit history tracking task progress and field dispatching.
15. **`complaint_evidence`**: Resolution proof records containing before/after photos, notes, and GPS coordinates.

### 4.2. Database Functions & Transactional RPCs
- `submit_complaint(...)`: Validates parameters, stores location, creates complaint, and initializes the first milestone timeline entry.
- `submit_vendor_application(...)`: Saves vendor business details, zone selections, schedules, and document links.
- `get_admin_stats()`: Aggregates real-time KPIs (total complaints, resolution rate, vendor approval rate, user counts).
- `suspend_user(user_id, reason)` & `reactivate_user(user_id)`: Enforces account moderation with auditing.
- `send_broadcast_notification(...)`: Inserts notification records across all active citizen profiles.
- `calculate_distance_meters(lat1, lon1, lat2, lon2)`: Deterministic Haversine distance calculator for on-site geo-verification.

### 4.3. Supabase Edge Functions
- `admin-create-staff`: Server-side endpoint with zero secret leakage. Verifies Admin JWT and permissions, calls `auth.admin.createUser`, creates `staff_profiles` row, performs atomic rollback on failure, and logs audit records.

### 4.4. Private Storage Buckets
- `complaint-photos`: Citizen grievance photos (`<owner_id>/...`).
- `vendor-documents`: Vendor KYC and site photos (`<owner_id>/...`).
- `complaint-evidence`: Field staff resolution proof photos (`<staff_id>/<complaint_id>/...`).

---

## 5. Offline & Caching Strategy

```
┌────────────────────────────────────────────────────────┐
│                   Data Request                         │
└──────────────────────────┬─────────────────────────────┘
                           │
             Is Cloud Backend Configured?
             ├── No ──> Load DemoData
             │
             └── Yes ──> Attempt Supabase Remote Fetch
                           ├── Success ──> Update AppState & Local Cache (Scoped to UserId)
                           │
                           └── Failure / Network Offline ──> Load Cached Reads for UserId
                                                             Display Non-blocking Offline Banner
```

1. **User Scoping:** Cached state is strictly partitioned by `cachedUserId`. If a new user signs in, or if a user logs out, sensitive cached records are purged immediately.
2. **Read-Only Offline Fallback:** Offline caching provides read access to previously loaded complaints, applications, and profile data during transient network drops.
3. **No Offline Write Queues:** All mutations (complaint submissions, vendor applications, profile updates) require a live connection to Supabase to guarantee immediate transactional verification and photo/document upload integrity.

---

## 6. Complete Directory Structure

```
d:\SmartNagpur\
├── .github/                       # CI/CD workflows and actions
├── android/                       # Native Android build configuration & gradle files
│   └── app/build.gradle.kts       # Android package IDs, SDK versions, Kotlin config
├── lib/
│   ├── admin_main.dart            # Admin Application entry point
│   ├── app.dart                   # Citizen Application routing & widget setup
│   ├── main.dart                  # Citizen Application entry point
│   ├── staff_main.dart            # Staff Application entry point
│   ├── core/
│   │   ├── config/                # Supabase configuration & URL validators
│   │   ├── localization/          # Bilingual AppStrings (EN & MR)
│   │   ├── services/              # GPS, media, document, and private file services
│   │   ├── theme/                 # Design tokens, AppColors, AppTypography, AppTheme
│   │   └── widgets/               # Reusable buttons, text fields, cards, badges, timeline, gallery
│   ├── data/
│   │   ├── adapters/              # Supabase admin & staff gateway adapters
│   │   ├── demo/                  # DemoData mock provider
│   │   ├── gateways/              # Gateway abstract contracts (Auth, Data, Admin, Staff)
│   │   ├── local/                 # JsonFileStore local file persistence
│   │   ├── remote/                # Remote Auth, Data, and File gateway contracts
│   │   ├── repositories/          # AppRepository and LocalAppRepository
│   │   └── supabase/              # Supabase citizen auth, data, and file gateways
│   ├── domain/
│   │   └── models/                # Typed domain models (Complaint, Vendor, Admin, Staff, User, etc.)
│   ├── features/
│   │   ├── admin/presentation/    # Admin screens (Dashboard, Complaints, Vendors, Users, etc.)
│   │   ├── auth/presentation/     # Auth screens (Login, Register, Recovery, etc.)
│   │   ├── bootstrap/             # Splash and Onboarding walkthrough
│   │   ├── complaints/            # Multi-step complaint wizard and photo/location widgets
│   │   ├── home/                  # Citizen home dashboard and quick actions
│   │   ├── news/                  # City announcements and news detail
│   │   ├── notifications/         # Notification inbox and category filtering
│   │   ├── profile/               # Edit profile, saved locations, settings, privacy, terms
│   │   ├── requests/              # Unified tracking and step-by-step milestone timeline
│   │   ├── search/                # Global search screen
│   │   ├── services/              # 10 Civic services catalog and service details
│   │   ├── shell/                 # Citizen bottom navigation shell
│   │   ├── staff/presentation/    # Staff screens (Login, Dashboard, Duty Toggle, Shell, Profile)
│   │   └── vendor/                # 4-step vendor application, zones, documents, renewal
│   └── state/
│       ├── admin_controller.dart  # Admin state coordination
│       ├── app_controller.dart    # Citizen state coordination
│       └── staff_controller.dart  # Staff state coordination
├── supabase/
│   ├── README.md                  # Supabase deployment and SQL execution guide
│   ├── functions/                 # Supabase Edge Functions (admin-create-staff)
│   ├── migrations/                # Versioned SQL migrations (202608170001, 202608180001, 202608190001)
│   └── tests/                     # Schema contract validation tests
├── test/                          # Unit, gateway, controller, and widget test suites
├── pubspec.yaml                   # Dependencies, assets, and project metadata
└── README.md                      # General project setup and run instructions
```

