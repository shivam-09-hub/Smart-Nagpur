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
- Expanded automated test coverage across `AppController`, `CloudAppController`, `PrivateFileStore`, `SupabaseConfig`, and widget trees (35 passing tests under `test/`).

### Staff Database Architecture & Foundation (2026-08-19)
- Authored migration `supabase/migrations/202608190001_smart_nagpur_staff.sql` introducing `staff_profiles`, `complaint_assignments`, and `complaint_evidence` tables with strict RLS and Haversine distance calculation (`calculate_distance_meters`).
- Created private Storage bucket `complaint-evidence` with RLS policies restricting upload to active staff and view access to authorized staff, admins, and complaint owners.
- Added contract tests in `supabase/tests/202608190001_smart_nagpur_staff_test.sql` validating all 16 security and schema constraints.

### Staff APK Foundation & Authentication (Step 5)
- Created dedicated Staff entry point `lib/staff_main.dart` with `StaffApp` shell, `StaffAuthGateway`, `StaffDataGateway`, `SupabaseStaffAuthGateway`, `SupabaseStaffDataGateway`, and `StaffController`.
- Implemented Staff login flow validating standard Supabase Auth with `staff_profiles` active status check and inactive account rejection.
- Created `StaffLoginScreen`, `StaffDashboardScreen` (with live duty toggle and profile info), `StaffTasksScreen` placeholder, `StaffProfileScreen`, and `StaffShell` 3-tab navigation.
- Added 11 automated unit tests in `test/staff_controller_test.dart` (46 total passing tests).

### Admin Complaint Assignment System (Step 6)
- Implemented transactional PostgreSQL RPC `assign_complaint` in `supabase/migrations/202608190001_smart_nagpur_staff.sql` with admin authentication, active staff validation, priority/instruction checking, atomicity, and timeline logging.
- Created domain model `ComplaintAssignment` with `AssignmentStatus` and `AssignmentPriority` enums.
- Added assignment methods to `AdminDataGateway`, `SupabaseAdminDataGateway`, and `AdminController`.
- Integrated Field Staff Assignment section into `AdminComplaintDetailScreen` with department pre-filtering, active staff dropdown, priority selector, instructions field, live assignment card, and reassignment flow.
- Added 8 automated unit tests in `test/complaint_assignment_test.dart` (54 total passing tests).

### Staff Task Consumption & Workflow (Step 7)
- Implemented transactional PostgreSQL RPCs `accept_complaint_assignment`, `start_complaint_assignment`, `complete_complaint_assignment` enforcing caller identity, active staff profile, previous valid state (`assigned` -> `accepted` -> `inProgress` -> `completed`), timeline recording, and complaint state synchronization.
- Added task retrieval, state transition methods, and realtime task subscription in `StaffDataGateway`, `SupabaseStaffDataGateway`, and `StaffController`.
- Built `StaffTasksScreen` with priority sorting (`urgent` -> `high` -> `medium` -> `low`), status filtering chips, and realtime task list updates.
- Built `StaffTaskDetailScreen` with full complaint information, admin directives banner, location coordinates, milestone timeline, and context-dependent action buttons (`Accept Task`, `Start Work`, `Complete Task`).
- Updated `StaffDashboardScreen` with live task workload overview metrics (Pending, Accepted, In Progress, Completed).
- Added 13 automated unit tests in `test/staff_task_workflow_test.dart` (68 total passing tests).

### Field Work Completion & Admin Verification Foundation (Step 8A)
- Decoupled field staff task completion from citizen complaint resolution: staff completion transitions assignment to `completed` and sets complaint to `underReview` ("Work Submitted for Verification").
- Added transactional PostgreSQL RPCs `approve_complaint_assignment` and `request_rework_complaint_assignment` verifying Admin/Supervisor credentials, prohibiting technician self-approval, creating timeline audit entries, and updating complaint status to `resolved` on approval or `inProgress` on rework.
- Updated `AssignmentStatus` enum with `reworkRequired` and `approved`.
- Added Admin verification UI card to `AdminComplaintDetailScreen` allowing review of technician notes and 1-tap Approve or Request Rework.
- Updated `StaffTaskDetailScreen` and `StaffTasksScreen` with "Work Submitted for Verification", Rework Notice, and "Start Rework" actions.
- Added automated contract tests in `supabase/tests/202608190001_smart_nagpur_staff_test.sql` and Flutter unit tests (73 passing tests total).

### GPS Location Verification & Field Evidence Foundation (Step 8B)
- Implemented real-device GPS proximity verification:
  - `LocationService.verifyStaffLocation` checks GPS service status, runtime permissions, accuracy threshold (≤50m), and Haversine distance (≤100m) against target complaint coordinates.
  - Added 1-tap Google Maps external turn-by-turn navigation via `LocationService.launchNavigation`.
  - Maintained full backward compatibility for Citizen complaint & vendor registration flows (`DeviceLocationService`, `LocationAccess`, `LocationServiceException`, `getCurrentLocation`, `openLocationSettings`, `openAppSettings`).
- Implemented Field Evidence Capture & Secure Storage:
  - Added `ComplaintEvidence` domain model with `EvidenceType` (`beforeWork`, `afterWork`, `inspectionReport`) and file helpers.
  - Implemented transactional PostgreSQL RPC `record_complaint_evidence` verifying caller assignment ownership, computing distance via server-side Haversine function, setting `is_geo_verified`, and appending milestone timeline entries.
  - Integrated private Supabase Storage bucket `complaint-evidence` using pathing structure `<staff_id>/<complaint_id>/<assignment_id>/<uuid>.<ext>` and signed URLs.
- Built Staff & Admin Evidence UIs:
  - `StaffTaskDetailScreen`: Added live GPS verification badge/card, Before-Work Photo capture, After-Work Photo capture, Inspection PDF picker, and dynamic action buttons.
  - `AdminComplaintDetailScreen`: Added Field Evidence section rendering on-site photos, geotags, accuracy, distance metrics, inspection PDF links, and signed URLs.
- Expanded test suite to 86 passing tests with zero analyzer issues.

### Production Security & Evidence Hardening (Step 8C)
- **Storage Security Hardening:**
  - Private `complaint-evidence` bucket with MIME restriction (`image/jpeg`, `image/png`, `image/webp`, `application/pdf`) and 10MB limit.
  - `storage.objects` RLS prevents path traversal (`..`, `//`, `\`), enforces `<staff_id>/<complaint_id>/<assignment_id>/<uuid>.<ext>` ownership, and validates assignment working state (`accepted`, `inProgress`, `reworkRequired`).
  - Implemented 300s (5-minute) short-lived expiration for all signed URLs in Staff and Admin gateways.
  - Restricted UPDATE/DELETE operations on storage objects and evidence records to active admins (evidence immutability).
- **Authoritative Server RPC Hardening (`record_complaint_evidence`):**
  - Explicit `SET search_path = public, pg_temp;` on all SECURITY DEFINER functions.
  - Strict lifecycle validation: rejects `afterWork` before work starts; rejects new evidence on `completed` or `approved` tasks; prevents duplicate `beforeWork` photos in non-rework state.
  - Path security: verifies path prefix structure and rejects path traversal, backslashes, double slashes, and null bytes.
  - Server-authoritative distance computation and geo-verification calculation.
- **Client-Side & Gateway Defensive Validation:**
  - Generated normalized UUID filenames (`<uuid>.<ext>`) to prevent file path manipulation.
  - Enforced file size checks (1 byte to 10MB) and extension/MIME compatibility before storage upload.
### Field Navigation & Real-World Staff UX (Step 9)
- **Enhanced LocationService Engine:**
  - Expanded `LocationVerificationResult` to 10 distinct states: `verified`, `outsideRadius`, `poorAccuracy`, `permissionDenied`, `permissionDeniedForever`, `serviceDisabled`, `timeout`, `mockDetected`, `staleLocation`, `error`.
  - Added robust detection for mock/fake GPS coordinates (`isMocked`), stale locations (>3 minutes old), impossible coordinates (out of range/0,0), and configurable timeouts (15s).
  - Enhanced `launchNavigation` supporting Google Maps turn-by-turn navigation intent, `geo:` URIs, and web fallbacks with encoded destination pin labels.
  - Provided direct system settings launcher helpers: `openLocationSettings()` (GPS toggle) and `openAppSettings()` (app permissions).
- **Staff Field UX Enhancements:**
  - `StaffTaskDetailScreen`: Redesigned Field Location & GPS card with live accuracy and proximity metrics, color-coded badges, 1-tap coordinate clipboard copying, context-aware SnackBar actions (e.g. "Enable GPS", "Settings", "Open Maps"), and inline diagnosis banner for non-verified states.
  - Dedicated "Navigate (Maps)" button and "Verify GPS" button with active progress spinner.
- **Automated Verification:**
  - Created `test/staff_location_navigation_test.dart` covering all 10 location states, mock GPS detection, timeout handling, coordinate range validation, and widget rendering.
  - Full suite expanded to 103 passing tests with 0 analyzer issues.

### Admin Operations & Verification Dashboard (Step 10)
- Created PostgreSQL RPC `get_admin_operations_dashboard(p_department, p_priority, p_status, p_staff_id, p_from_date, p_to_date)` in `supabase/migrations/202608190001_smart_nagpur_staff.sql` with admin/supervisor authorization, supervisor department isolation, single-roundtrip aggregation (complaint status breakdown, assignment status breakdown, staff workload summary, individual staff workloads, and verification queue with lateral evidence summaries).
- Added performance indexes: `idx_complaint_assignments_completed_priority` and `idx_complaints_status_created`.
- Created domain models in `lib/domain/models/admin_operations.dart`: `VerificationQueueItem`, `StaffWorkloadItem`, `StaffWorkloadSummary`, `AdminOperationsFilter`, and `AdminOperationsDashboard`.
- Added gateway interfaces and Supabase adapter implementation for `getOperationsDashboard`.
- Extended `AdminController` with `loadOperationsDashboard`, `setOperationsFilter`, `clearOperationsFilter`, and reactive state management.
- Built `AdminOperationsScreen` in `lib/features/admin/presentation/admin_operations_screen.dart` with:
  - Scrollable TabBar with live amber badge count for tasks awaiting verification.
  - Interactive Filter Bar (Department dropdown, Priority dropdown, Reset chip).
  - Tab 1 (Verification Queue): Awaiting review cards displaying technician notes, elapsed age, GPS verification status badge, Before/After photo badges, inspection PDF badge, and direct 1-tap review CTA.
  - Tab 2 (Staff Workload): Summary metric cards (On-Duty / Active staff, In-Progress tasks, Pending tasks) and list of technicians with duty badges and active task counts.
  - Tab 3 (Workload Breakdown): Interactive metric chips showing complaints across all 7 lifecycle states and assignments across all 6 assignment states.
- Enhanced `AdminDashboardScreen` with a dedicated "Field Operations & Verification" action card and quick action button.
- Added Section 11 SQL contract tests in `supabase/tests/202608190001_smart_nagpur_staff_test.sql`.
- Added test suite `test/admin_operations_test.dart` (8 tests). Total test suite reached 111/111 passing tests with 0 analyzer issues.

### Full Production Security & RLS Audit (Step 11)
- **Threat Modeling:** Evaluated 6 distinct actor profiles (Citizen, Field Worker, Supervisor, Admin, Unauthenticated Attacker, Compromised Client).
- **Vulnerability Remediation:**
  - *VULN-01 (High):* Added `is_active_admin()` guards across all 14 admin analytics and data retrieval RPCs (`get_complaint_stats`, `get_admin_stats`, `get_admin_pending_complaints`, `get_admin_complaint_details`, `get_admin_vendor_applications`, etc.) to prevent unauthorized citizen data leakage and IDOR.
  - *VULN-02 (High):* Added `check_staff_profile_update_integrity` trigger on `staff_profiles` preventing field workers from modifying `role`, `department`, `employee_id`, `is_active`, or `created_by`.
  - *VULN-03 (Medium):* Enforced explicit table-level `REVOKE ALL FROM public, anon` and column-level `GRANT UPDATE (phone, is_on_duty, last_active_at)` on `staff_profiles`.
  - *VULN-04 (Low):* Enforced `SET search_path = public, pg_temp` across all SECURITY DEFINER functions to eliminate search-path poisoning risks.
  - *VULN-05 (Low):* Added `.env`, `.env.*`, `*.env` to `.gitignore`.
- **Automated Security Regression Tests:** Added Section 12 SQL contract tests verifying non-admin RPC rejection and staff privilege escalation rejection.

### Production Performance & Resilience (Step 12)
- **N+1 Elimination & Parallel URL Hydration:**
  - Parallelized 4 stats RPCs in `SupabaseAdminDataGateway.getAdminStats` with `Future.wait`, reducing latency by ~75%.
  - Parallelized signed URL hydration for photos and documents in `getPendingComplaints`, `getPendingApplications`, and `getComplaintEvidence`.
  - Parallelized missing file download validation in `SupabaseRemoteDataGateway.loadCurrentUserData`.
- **High-Performance Database Indexing:**
  - Added composite and partial indexes in migrations: `idx_complaints_status_created`, `idx_complaints_created`, `idx_vendor_applications_status_created`, `idx_vendor_applications_created`, `idx_admin_reviews_lookup`, `idx_user_suspensions_active`, `idx_admin_notifications_created`, `idx_complaint_assignments_status_assigned`.
  - Added Section 13 index contract verification in `supabase/tests/202608190001_smart_nagpur_staff_test.sql`.
- **Realtime Lifecycle & Memory Management:**
  - Added **500ms debounce timers** in `StaffController` and `AdminController` to collapse rapid multi-row realtime bursts into single batched refreshes.
  - Implemented `dispose()` in `StaffController` and `AdminController` to cancel timers and cleanly unsubscribe from Supabase channels.
- **In-Flight Mutation Guards:**
  - Added in-flight mutex tracking (`_inFlightTasks`, `_inFlightComplaints`, `_inFlightAssignments`, `_isUploadingEvidence`) preventing duplicate clicks and submissions across all staff task transitions, evidence uploads, complaint assignments, and admin reviews.
- **Timeout & Failure Resilience:**
  - Standardized 15–20s timeout guards with clean `TimeoutException` and `SocketException` mapping to user-safe error messages.
  - Strict adherence to offline integrity: server-authoritative states are never falsely reported as completed offline, and non-idempotent mutations are never blindly retried.
- **Automated Verification:**
  - Created `test/performance_resilience_test.dart` (8 new tests).
  - Total test suite expanded to **119/119 passing tests** with **0 analyzer issues**.

### Production Release Preparation (Step 13)
- **Application ID & Flavor Isolation:**
  - Citizen (`com.smartnagpur.citizen`, `lib/main.dart`, "Smart Nagpur")
  - Admin (`com.smartnagpur.admin`, `lib/admin_main.dart`, "Smart Nagpur Admin")
  - Staff (`com.smartnagpur.staff`, `lib/staff_main.dart`, "Smart Nagpur Staff")
- **Signing & ProGuard/R8:**
  - Configured `android/app/build.gradle.kts` with dynamic `key.properties` loading and fallback to debug keystore for development/CI.
  - Created `android/app/proguard-rules.pro` protecting Flutter engine, plugins, and reflection signatures.
- **Manifest & Deep Linking:**
  - Updated `android/app/src/main/AndroidManifest.xml` with deep-link intent filters for all 3 applications (`com.smartnagpur.citizen`, `com.smartnagpur.admin`, `com.smartnagpur.staff`).
  - Verified 4 necessary permissions (`INTERNET`, `CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`); 0 unnecessary or invasive permissions.
- **Release Build Verification:**
  - Successfully compiled `app-citizen-release.apk` (61.6 MB), `app-admin-release.apk` (57.0 MB), and `app-staff-release.apk` (54.5 MB).
  - `flutter analyze --no-pub` -> 0 issues.
  - `flutter test --no-pub` -> 119/119 passing tests.

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
