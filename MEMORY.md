# Project Memory & Context Bank — Smart Nagpur

**Last Updated:** 2026-08-17  
**Project Status:** Active Development / Dual Flavor Ready (Citizen & Admin)  
**Primary Language/Framework:** Flutter (Dart SDK `^3.11.5`)  
**Backend:** Supabase (PostgreSQL 15+, Auth, Storage, RLS, RPCs)

---

## 1. Quick Context Snapshot (Token Optimization)

This document allows developers and AI assistants to instantly restore complete project context without expensive codebase-wide scanning.

### Core Stack & Architecture
- **Framework:** Flutter with Dart 3.x strict null-safety and `flutter_lints: ^6.0.0`.
- **State Management:** Flutter's built-in `ChangeNotifier` and `ListenableBuilder` (`AppController` for Citizen app, `AdminController` for Admin app). No third-party state managers (Bloc/Riverpod).
- **Backend:** Supabase project `hcpcycfvupjuklhcaxzg.supabase.co`. Client uses publishable key only (`sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y`).
- **Storage Buckets:** Private buckets `complaint-photos` and `vendor-documents` with RLS policies restricting access to owner (`<auth.uid()>/...`) and authorized admins.
- **Deep Links:** `com.smartnagpur.citizen://login-callback/` and `com.smartnagpur.admin://login-callback/`.
- **Flavors:**
  1. `citizen`: `com.smartnagpur.citizen` (Entry: `lib/main.dart`)
  2. `admin`: `com.smartnagpur.admin` (Entry: `lib/admin_main.dart`)

---

## 2. Key Architectural Decisions & Invariants

1. **Gateway Abstraction:**
   - All backend calls go through abstract gateway interfaces (`AuthGateway`, `RemoteDataGateway`, `AdminAuthGateway`, `AdminDataGateway`).
   - The UI and domain models never import or reference `supabase_flutter` directly. This enables 100% deterministic unit/widget testing without cloud dependencies.
2. **Security & RLS Invariants:**
   - Secret keys, service-role keys, and database passwords are **NEVER** embedded in the mobile client.
   - All database updates and milestone additions are handled via PostgreSQL transactional RPCs (`submit_complaint`, `submit_vendor_application`, `suspend_user`, etc.).
   - Row-Level Security (RLS) restricts all citizen operations to `auth.uid() = user_id`.
3. **Offline Caching Policy:**
   - Local storage (`LocalAppRepository` + `JsonFileStore`) caches onboarding preferences, locale, and user-ID-scoped reads.
   - Cached reads provide temporary offline fallback; offline write queuing is intentionally prohibited (submissions require live connection).
   - Logging out immediately purges sensitive cached data via `_clearProtectedData()`.
4. **Demo Mode Isolation:**
   - Demo mode is strictly local-only and uses in-memory `DemoData`. It never calls Supabase or transmits mock records to the cloud.

---

## 3. Historical Changelog & Milestones

### Greenfield & Architecture Foundation (2026-08-17)
- Initialized clean Flutter Android application with ID `com.smartnagpur.citizen`.
- Configured dependencies: `supabase_flutter: ^2.16.0`, `geolocator: ^14.0.3`, `image_picker: ^1.2.3`, `file_picker: ^12.0.0`, `path_provider: ^2.1.6`, `intl: ^0.20.2`, `uuid: ^4.6.0`.
- Built centralized design system (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppTheme`, `ServiceTheme`) and bilingual localization (`AppStrings` for English and Marathi).
- Implemented core domain models: `ComplaintRecord`, `VendorApplication`, `UserProfile`, `ProblemLocation`, `AppNotification`, `NewsItem`, `ServiceDefinition`.

### Citizen Feature Complete Implementation
- Implemented Splash and Onboarding walkthrough screens with persistent state.
- Implemented Auth suite: Login, Register, Forgot Password, Verification, Password Recovery.
- Built Home screen with quick-action 10 civic service grid, recent requests, and news updates.
- Built Universal Complaint Reporting Wizard with service selection, GPS location detection, `DevelopmentMap` pin placement, camera/gallery photo picker (up to 3 images), and review step.
- Built Street Vendor Permitting Hub with 4-step registration wizard, zone map explorer, document upload center (PDF/JPG/PNG), application status tracker, and license renewal.
- Built My Requests unified tracking center with step-by-step milestone timelines.
- Built Notification Center, City News, Global Search, and Profile/Settings (language switch, saved locations, privacy, terms, help).

### Supabase Cloud Backend Integration
- Authored idempotent SQL migration `supabase/migrations/202608170001_smart_nagpur_backend.sql` creating tables (`profiles`, `complaints`, `vendor_applications`, `notifications`), RLS policies, transactional RPCs, Storage buckets, and Auth trigger.
- Created schema contract test `supabase/tests/schema_contract.sql`.
- Added `SupabaseConfig` environment parser and publishable key validator.
- Implemented `SupabaseAuthGateway`, `SupabaseRemoteDataGateway`, and `SupabaseFileGateway`.

### Municipal Admin Application & Build Flavors (2026-08-18)
- Designed admin SQL migration `supabase/migrations/202608180001_smart_nagpur_admin.sql` creating `admin_profiles`, `admin_reviews`, `admin_notifications`, `user_suspensions`, and admin RPCs (`get_admin_stats`, `suspend_user`, `send_broadcast_notification`, etc.).
- Created admin domain entities (`AdminProfile`, `AdminStats`, `AdminReview`) supporting 6 roles (`superAdmin`, `complaintReviewer`, `vendorReviewer`, `reportViewer`, `notificationManager`, `userManager`).
- Created `lib/admin_main.dart` and `AdminController`.
- Built 8 admin screens: Login, Dashboard (KPIs), Complaints Queue, Complaint Detail & Review, Vendors Queue, Vendor Detail & Document Review, Notifications Broadcast Composer, and User Account Manager.
- Configured Gradle build flavors (`citizen` and `admin`).

### Device Validation & Test Hardening
- Tested debug build on physical Vivo V2142 (Android 14). Resolved a cold-start listener assertion by deferring initialization until post-frame callback.
- Expanded automated test coverage across `AppController`, `CloudAppController`, `PrivateFileStore`, `SupabaseConfig`, and widget trees (25 passing tests under `test/`).

---

## 4. Current File Map

```
d:\SmartNagpur\
├── PRD.md                             # Complete Project Requirements Document
├── ARCHITECTURE.md                    # System architecture, data flow, and layers
├── RULES.md                           # AI boundaries, coding standards, and security rules
├── PHASES.md                          # Implementation phases, progress, and future roadmap
├── DESIGN.md                          # Visual design system, color palette, and typography tokens
├── MEMORY.md                          # This context bank and historical memory log
├── README.md                          # General project setup and run instructions
├── ADMIN_README.md                    # Admin application specific guide
├── BUILD_FLAVORS_GUIDE.md             # Guide for building citizen vs admin APKs
├── pubspec.yaml                       # Flutter dependencies and assets
├── lib/
│   ├── main.dart                      # Citizen App Entry Point
│   ├── admin_main.dart                # Admin App Entry Point
│   ├── app.dart                       # Citizen App Routing & Shell
│   ├── core/                          # Tokens, Theme, Localization, Services, Widgets
│   ├── domain/models/                 # Domain entities & Drafts
│   ├── data/                          # Gateways, Adapters, Supabase, Local JSON Store
│   ├── state/                         # AppController & AdminController
│   └── features/                      # Citizen & Admin presentation modules
└── supabase/
    ├── README.md                      # Backend setup and SQL deployment instructions
    ├── migrations/                    # Checked-in SQL migrations
    └── tests/                         # Contract tests
```

---

## 5. Next Immediate Action Items

1. **Supabase SQL Migration Deployment:** Run `202608170001_smart_nagpur_backend.sql` and `202608180001_smart_nagpur_admin.sql` in Supabase SQL Editor for the target project.
2. **Redirect URLs Allowlist:** Add `com.smartnagpur.citizen://login-callback/` and `com.smartnagpur.admin://login-callback/` in Supabase Auth settings.
3. **NMC Municipal Integration:** Connect Supabase webhooks to official NMC e-Nagarseva APIs when credentials and endpoints are provisioned.
