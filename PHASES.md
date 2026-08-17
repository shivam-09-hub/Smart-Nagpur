# Project Implementation Phases & Roadmap — Smart Nagpur

This document outlines the step-by-step development phases, milestone deliverables, testing criteria, and future roadmap for the **Smart Nagpur** platform.

---

## Roadmap Summary & Progress

| Phase | Description | Key Deliverables | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1** | Foundation & Core Infrastructure | Theme tokens, localization (EN/MR), gateway interfaces, local JSON store, demo data. | **Complete** |
| **Phase 2** | Citizen Frontend & Workflows | 10 services, complaint reporting wizard, vendor registration, request tracking, news, search, profile. | **Complete** |
| **Phase 3** | Supabase Backend Integration | PostgreSQL schema, RLS, transactional RPCs, Storage buckets, Auth triggers, contract tests. | **Complete** |
| **Phase 4** | Municipal Admin Portal & Flavors | Admin domain models, Supabase admin RPCs, `admin_main.dart`, AdminController, 8 admin screens, build flavors. | **Complete** |
| **Phase 5** | Testing & Physical Device Validation | Android 14 physical device testing, cold-start lifecycle fix, regression test suite (46 tests). | **Complete** |
| **Phase 6** | Field Staff Portal & Task Engine | `staff_profiles`, `complaint_assignments`, `complaint_evidence`, `lib/staff_main.dart`, `StaffController`, Edge Functions. | **In Progress (Foundation Complete)** |
| **Phase 7** | Municipal ERP Integration & Production | NMC API integration, SMS OTP via DLT, Push notifications (FCM), Vector map provider, Play Store release. | **Planned** |

---

## Phase Details

### Phase 1: Foundation & Core Infrastructure (Completed)
- **Goal:** Establish a scalable, clean Flutter project architecture with design tokens, localization, and mock boundaries.
- **Key Milestones:**
  - Setup Flutter project with Dart 3.x strict null-safety and lint configurations.
  - Create centralized design system in `lib/core/theme/` (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppTheme`, `ServiceTheme`).
  - Implement bilingual translation engine `AppStrings` with English (`en`) and Marathi (`mr`) string catalogs.
  - Implement abstraction layers for device capabilities: `LocationService`, `MediaPickerService`, `DocumentPickerService`, `PrivateFileStore`.
  - Implement `LocalAppRepository` backed by `JsonFileStore` for local preferences and state caching.
  - Create `DemoData` provider with comprehensive realistic mock records.

---

### Phase 2: Citizen Application UI/UX & Workflows (Completed)
- **Goal:** Implement the complete citizen-facing mobile application across all 10 civic service domains.
- **Key Milestones:**
  - **Bootstrap:** Animated splash screen with route orchestration and onboarding walkthrough.
  - **Authentication:** Email/password login, registration, password recovery, verification placeholders, and guest demo mode.
  - **Home Dashboard:** Hero announcements, quick action service grid, recent activity feed, emergency contacts.
  - **10 Service Hubs:** Detailed service descriptions, FAQs, and action triggers for Vendor, Waste, Water, Roads, Animals, Drainage, Streetlights, Public Spaces, Encroachment, and Other.
  - **Universal Complaint Reporting Wizard:** Multi-step wizard with category selection, issue description, camera/gallery photo picker (up to 3 images), GPS location detection with `DevelopmentMap` pin placement, and summary review.
  - **Street Vendor Permitting Hub:** 4-step vendor application wizard, zone explorer, document upload center (PDF/JPG/PNG), application status tracking, and license renewal flow.
  - **My Requests & Milestone Timelines:** Unified list view for complaints and vendor applications with step-by-step progress tracking.
  - **Notification Center & City News:** Filterable notification inbox and city announcement reading interface.
  - **Profile & Settings:** Profile editing, saved locations, language toggle, notification preferences, privacy policy, terms of service, and help desk.

---

### Phase 3: Supabase Cloud Backend & Security (Completed)
- **Goal:** Replace purely mock persistence with production-grade Supabase Cloud infrastructure.
- **Key Milestones:**
  - Designed relational PostgreSQL schema: `profiles`, `complaints`, `vendor_applications`, `notifications`.
  - Configured Row-Level Security (RLS) policies enforcing `auth.uid() = user_id` on all citizen operations.
  - Implemented transactional PostgreSQL RPCs (`submit_complaint`, `submit_vendor_application`) to ensure atomic writes and server-controlled status workflows.
  - Configured private Supabase Storage buckets (`complaint-photos`, `vendor-documents`) with owner-prefixed security policies.
  - Configured Supabase Auth profile trigger (`handle_new_user`) to automatically initialize user profiles upon registration.
  - Implemented custom scheme deep links (`com.smartnagpur.citizen://login-callback/`) for password recovery and email confirmation.
  - Built schema contract validation script `supabase/tests/schema_contract.sql`.

---

### Phase 4: Municipal Admin Portal & Build Flavors (Completed)
- **Goal:** Build an administrative control center for municipal officers and configure dual-app build flavors.
- **Key Milestones:**
  - Designed Admin PostgreSQL schema: `admin_profiles`, `admin_reviews`, `user_suspensions`, `admin_notifications`.
  - Created Admin RPCs: `get_admin_stats`, `get_complaint_stats`, `get_vendor_stats`, `suspend_user`, `reactivate_user`, `send_broadcast_notification`, `add_complaint_timeline`, `add_application_timeline`.
  - Implemented Admin Domain Models (`AdminProfile`, `AdminStats`, `AdminReview`) with 6 distinct administrative roles (`superAdmin`, `complaintReviewer`, `vendorReviewer`, `reportViewer`, `notificationManager`, `userManager`).
  - Created `lib/admin_main.dart` and `AdminController`.
  - Built 8 specialized admin screens: Admin Login, Dashboard (KPI cards & charts), Complaints Queue, Complaint Detail & Review, Vendors Queue, Vendor Detail & Document Review, Notifications Broadcast Composer, and User Account Manager.
  - Configured Gradle build flavors (`citizen` and `admin`) with separate application IDs and manifest configurations.

---

### Phase 5: Hardware Verification & Regression Testing (Completed)
- **Goal:** Verify cold-start reliability on physical Android hardware and establish comprehensive regression test suites.
- **Key Milestones:**
  - Installed and validated release builds on physical Android devices (Vivo V2142 on Android 14 and Infinix X680D on Android 10).
  - Built comprehensive automated test suite (46 passing tests under `test/`) covering Citizen, Admin, and Staff state flows.
  - Verified clean `flutter analyze` and split APK generation (`arm64-v8a`, `armeabi-v7a`, `universal`).

---

### Phase 6: Field Staff Portal & Task Resolution Engine (Completed)
- **Goal:** Build on-ground field staff application for complaint dispatching, task acceptance, on-site GPS verification, and completion proof uploads.
- **Key Milestones:**
  - **Database Foundation:** Created `staff_profiles`, `complaint_assignments`, `complaint_evidence` tables, and Haversine distance calculator in `supabase/migrations/202608190001_smart_nagpur_staff.sql`.
  - **Secure Staff Provisioning:** Implemented `admin-create-staff` Supabase Edge Function eliminating `service_role` exposure from mobile code.
  - **Staff App Foundation:** Created `lib/staff_main.dart`, `StaffController`, `StaffProfileScreen`, `StaffDashboardScreen` with live shift duty toggle, and `StaffShell` 3-tab navigation.
  - **Complaint Dispatching & Assignment Lifecycle (Steps 6–8A):** Implemented `assign_complaint`, `accept_complaint_assignment`, `start_complaint_assignment`, `complete_complaint_assignment`, `approve_complaint_assignment`, `request_rework_complaint_assignment`.
  - **GPS Verification & Field Evidence (Step 8B):** Real-time GPS distance/accuracy check, Before/After photos, inspection PDF uploads with signed URLs, and full Admin verification UI.
  - **Production Security & Evidence Hardening (Step 8C):** Strict storage and RPC hardening against path traversal, authoritative server distance calculation, short-lived signed URLs (5m), and 22 SQL security contract tests.
  - **Field Navigation & Real-World Staff UX (Step 9):** Robust 10-state GPS failure handling (GPS disabled, permission states, timeout, mock location detection, stale fix, poor accuracy, outside radius), prominent Google Maps / geo intent navigation launcher, 1-tap coordinate copy, and 103 passing automated tests.
  - **Admin Operations & Verification Dashboard (Step 10):** Single-roundtrip server-side PostgreSQL aggregation RPC `get_admin_operations_dashboard`, dedicated `AdminOperationsScreen` with live-badged Verification Queue, staff workload tracking, lifecycle status breakdown chips, department/priority filters, and full test suite (111 passing tests).
  - **Full Production Security & RLS Audit (Step 11):** 30-vector audit, 6-actor threat model, `is_active_admin()` guards on all admin RPCs, `check_staff_profile_update_integrity` trigger on `staff_profiles`, table `REVOKE ALL`, `SET search_path = public, pg_temp` on all functions, and `.env*` gitignore protection. Full test suite: 111/111 passing tests.
  - **Production Performance & Resilience (Step 12):** N+1 query elimination, parallelized stats RPCs and signed URL generation (`Future.wait`), high-performance composite/partial database indexes, 500ms realtime debouncing, channel unsubscribe in controller `dispose()`, in-flight duplicate submission mutex guards, 15–20s timeout standardization, and safe read-only retry policies. Full test suite: 119/119 passing tests with 0 analyzer issues.
  - **Production Release Preparation (Step 13):** Isolated application IDs and flavors (`com.smartnagpur.citizen`, `com.smartnagpur.admin`, `com.smartnagpur.staff`), ProGuard/R8 rules, manifest deep linking filters, verified 0 unnecessary permissions, and validated standalone release APK compilation for all 3 targets. Full test suite: **119/119 passing tests** with 0 analyzer issues.


---

### Phase 7: Municipal ERP Integration & Production Launch (Planned / Future Roadmap)
- **Goal:** Connect Smart Nagpur to official municipal backend services and deploy to Google Play Store.
- **Milestones:**
  1. **Nagpur Municipal Corporation (NMC) API Bridge:** Connect Supabase webhook workers or edge functions to official NMC e-Nagarseva grievance dispatch APIs.
  2. **Indian Telecom SMS OTP Authentication:** Integrate SMS Gateway with Telecom DLT-registered templates for mobile-first OTP login.
  3. **Push Notifications:** Integrate Firebase Cloud Messaging (FCM) for real-time status alerts and city-wide emergency broadcasts.
  4. **Vector Mapping Provider:** Integrate Mapbox or Google Maps SDK behind `LocationService` with official municipal ward GIS boundary layers.
  5. **Play Store Deployment:** Generate signed Android App Bundles (`.aab`) for `com.smartnagpur.citizen`, `com.smartnagpur.admin`, and `com.smartnagpur.staff`.
