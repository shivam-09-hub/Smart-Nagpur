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
| **Phase 5** | Testing & Physical Device Validation | Android 14 physical device testing, cold-start lifecycle fix, regression test suite (25 tests). | **Complete** |
| **Phase 6** | Municipal ERP Integration & Production | NMC API integration, SMS OTP via DLT, Push notifications (FCM), Vector map provider, Play Store release. | **Planned** |

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
  - Installed and validated debug builds on physical Android 14 device (Vivo V2142).
  - Resolved cold-start listener assertion by deferring controller initialization until after the first frame.
  - Built comprehensive automated test suite (25 tests under `test/`) covering `AppController`, `CloudAppController`, `PrivateFileStore`, `SupabaseConfig`, and widget flows.
  - Verified clean `flutter analyze` and successful APK build outputs.

---

### Phase 6: Municipal ERP Integration & Production Launch (Planned / Future Roadmap)
- **Goal:** Connect Smart Nagpur to official municipal backend services and deploy to Google Play Store.
- **Milestones:**
  1. **Nagpur Municipal Corporation (NMC) API Bridge:** Connect Supabase webhook workers or edge functions to official NMC e-Nagarseva grievance dispatch APIs.
  2. **Indian Telecom SMS OTP Authentication:** Integrate SMS Gateway with Telecom DLT-registered templates for mobile-first OTP login.
  3. **Push Notifications:** Integrate Firebase Cloud Messaging (FCM) for real-time status alerts and city-wide emergency broadcasts.
  4. **Vector Mapping Provider:** Integrate Mapbox or Google Maps SDK behind `LocationService` with official municipal ward GIS boundary layers.
  5. **Play Store Deployment:** Generate signed Android App Bundles (`.aab`) for both `com.smartnagpur.citizen` and `com.smartnagpur.admin` with production release signing configs.
