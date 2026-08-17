# Project Requirements Document (PRD) — Smart Nagpur

**Project Name:** Smart Nagpur  
**Platform:** Flutter (Android Mobile Application & Admin Portal)  
**Backend:** Supabase (Auth, PostgreSQL, Storage, RLS, RPCs)  
**Target Municipality:** Nagpur Municipal Corporation (NMC), Maharashtra, India  
**Target Package IDs:** `com.smartnagpur.citizen` (Citizen App), `com.smartnagpur.admin` (Admin App), `com.smartnagpur.staff` (Staff App)  
**Document Version:** 1.0.0  
**Status:** Implemented & Verified (Production Ready Milestone)


---

## 1. Executive Summary & Vision

**Smart Nagpur** is a next-generation civic engagement and municipal service delivery mobile application built for the citizens, commercial vendors, and municipal officers of Nagpur. The platform bridges the communication gap between citizens and urban governance by enabling instant problem reporting, street vendor registration and zone compliance, real-time resolution tracking, city announcements, and an administrative control panel for municipal officials.

### Core Objectives
1. **Empower Citizens:** Enable seamless reporting of civic grievances (potholes, garbage, water leaks, stray animals, faulty streetlights, encroachments) with photo evidence and GPS coordinates.
2. **Streamline Street Vendor Operations:** Provide a structured digital onboarding and zone permit management system for street vendors, ensuring urban order and compliance with local municipal vendor bylaws.
3. **Transparent Resolution Tracking:** Provide end-to-end milestone timelines for all citizen grievances and vendor applications.
4. **Administrative Efficiency:** Offer municipal officers role-based access control (RBAC) to triage complaints, review vendor applications, manage user accounts, and broadcast critical city notifications.
5. **Robust & Secure Architecture:** Leverage Supabase for secure cloud authentication, owner-isolated PostgreSQL storage via Row-Level Security (RLS), transactional RPCs, and private object storage.

---

## 2. Target User Personas

| User Persona | Key Needs & Pain Points | Primary Features Used |
| :--- | :--- | :--- |
| **Citizens of Nagpur** | Wants quick, painless reporting of civic problems in their ward; needs proof and live tracking of municipal response; needs local language support (Marathi). | Home, 10 Civic Services, Complaint Wizard (GPS + Photos), My Requests (Timeline), Notifications, City News, Profile/Settings (Marathi/English). |
| **Street Vendors & Hawkers** | Needs official permits for designated vending zones, certificate renewals, document verification, and operating schedule approvals without bureaucratic delays. | Vendor Hub, 4-Step Vendor Application Wizard, Document Upload Center, Zone Explorer, Application Status Tracker, License Renewal. |
| **Municipal Review Officers & Admins** | Needs to review, verify, reject, or assign civic complaints; inspect vendor documents; assign field workers; broadcast alerts; manage suspicious user activity; provision field staff accounts. | Admin Login, Admin Dashboard (KPIs & Metrics), Complaint Triage Queue, Vendor Document Reviewer, Broadcast Composer, User Suspension Manager, Staff Provisioning. |
| **Field Maintenance Staff** | Needs direct access to assigned field tasks, on-duty shift toggle, GPS distance verification, and before/after resolution evidence uploads. | Staff Login, Staff Dashboard, Duty Toggle, Task Dispatching, Evidence Camera, Profile. |

---

## 3. Scope & Feature Requirements

### 3.1. Onboarding, Localization & Authentication
- **Bilingual Interface:** Full support for English (`en`) and Marathi (`mr`).
- **Splash & Onboarding Walkthrough:** Introductory slides introducing civic reporting, vendor permits, and request tracking with persistent completion flags.
- **Authentication Modes:**
  - **Email & Password:** Secure sign-up, login, and logout backed by Supabase Auth across Citizen, Admin, and Staff applications.
  - **Password Recovery & Email Confirmation:** Secure deep links via Android custom scheme `com.smartnagpur.citizen://login-callback/`, `com.smartnagpur.admin://login-callback/`, and `com.smartnagpur.staff://login-callback/`.
  - **Offline Demo Mode:** Explicit guest/demo sandbox with sample data; strictly local-only and isolated from cloud storage.

### 3.2. 10 Core Municipal Civic Services
The platform structures all urban grievances into 10 distinct service domains:
1. **Street Vendor Services (`vendor`):** Zone allocation, registration, hawker certificate, renewal.
2. **Garbage & Sanitation (`garbage` / `waste`):** Overflowing dumpsters, missed door-to-door collection, unsegregated waste, street sweeping.
3. **Water Supply (`water`):** Pipeline leaks, low water pressure, contaminated supply, tanker requests.
4. **Roads & Traffic Infrastructure (`roads`):** Potholes, damaged dividers, missing manhole covers, uneven paving.
5. **Stray Animals & Veterinary (`animals`):** Stray dog menace, injured animals, cattle on main roads, carcass removal.
6. **Drainage & Sewerage (`drainage`):** Blocked stormwater drains, sewage overflow, broken gutter slabs.
7. **Streetlights & Electrical (`streetlights`):** Non-functional lights, exposed live wires, broken poles, daytime lighting.
8. **Public Spaces & Parks (`publicSpaces`):** Overgrown vegetation, broken park benches, vandalized playground equipment.
9. **Encroachment & Illegal Structures (`encroachment`):** Footpath blockage, unauthorized commercial stalls, illegal banners.
10. **Other Civic Inquiries (`other`):** Miscellaneous municipal inquiries and general public property issues.

### 3.3. Universal Complaint Reporting Wizard
- **Step 1: Service & Issue Selection:** Choose civic category and pre-populated issue type or enter custom description.
- **Step 2: Photo Attachment:** Capture from camera or select from gallery (up to 3 images, JPEG/PNG/WebP, max 10MB each) with instant preview and deletion.
- **Step 3: Location Pinning:**
  - Automated GPS fetching via `geolocator` with accuracy indicator.
  - Interactive adjustable map pin (`DevelopmentMap`) with manual address input.
- **Step 4: Contact & Verification:** Citizen contact phone number, address confirmation, and review step before final submission.
- **Transactional Submission:** Uploads images to private bucket `complaint-photos/<uid>/<group_id>/...`, then atomically creates complaint record via database RPC.

### 3.4. Street Vendor Management & Permitting
- **4-Step Multi-Step Application:**
  1. **Personal Information:** Full name, mobile, email, residential address, Aadhaar/Govt identity info.
  2. **Business Details:** Business name, type (food, apparel, services, etc.), category, products/services list, registration number.
  3. **Zone & Schedule:** Preferred municipal zone (e.g., Sitabuldi, Dharampeth, Sadar), location coordinates, operating days, daily start & end time, duration (Permanent / Seasonal), outlet type (Cart / Stall / Mobile).
  4. **Document Center:** Upload identity proof, address proof, food safety certificate (FSSAI), previous municipal receipt, and character certificate (PDF/JPEG/PNG).
- **Vendor License Renewal:** Express renewal flow for existing permit holders.
- **Zone Explorer:** Browse designated hawking, non-hawking, and restricted commercial zones across Nagpur.

### 3.5. Unified Request Tracking & Status Timelines
- **Unified Request Center:** Consolidated view of citizen complaints and vendor applications.
- **Filterable Statuses:** Active (Submitted, Under Review, Assigned, In Progress, Location Assessment) vs Completed (Resolved, Approved, Rejected).
- **Interactive Milestone Timeline:** Chronological step-by-step audit trail showing timestamps, assigned departments, and official municipal remarks.

### 3.6. Notifications & City News
- **Notification Inbox:** System updates, status change alerts, emergency notices, read/unread state tracking.
- **City News & Press Releases:** Ward advisories, road repair schedules, water shut-off notices, monsoon alerts, search and category filtering.
- **Global Search:** Instant search across services, news articles, and FAQs.

### 3.7. Profile & Settings
- **Profile Management:** Edit name, phone number, address, and view account registration metadata.
- **Saved Locations:** Quick selection of Home, Work, and frequently reported civic spots.
- **Preferences:** Language toggle (English / Marathi), notification preferences, Privacy Policy, Terms of Service, and Help Desk.

### 3.8. Municipal Admin Portal (`com.smartnagpur.admin`)
- **Role-Based Access Control (RBAC):**
  - `superAdmin`: Unrestricted system oversight, configuration, and staff provisioning.
  - `complaintReviewer`: Triage, update status, assign field workers, and add remarks to complaints.
  - `vendorReviewer`: Assess vendor applications, verify uploaded documents, approve/reject permits.
  - `notificationManager`: Compose broadcast alerts and targeted citizen notifications.
  - `userManager`: Audit user accounts, suspend bad actors, reactivate accounts, and create staff profiles.
  - `reportViewer`: High-level metrics, daily/monthly resolution stats.
- **Live Admin Dashboard:** Resolution rate KPI, vendor approval rate, pending review queues, and daily trend charts.
- **Complaint & Vendor Review Workflows:** Detailed inspection screens with full document viewing, photo review, location maps, status update modal, and official review scoring.
- **Broadcast Composer:** Instant system-wide announcements by category (Emergency, Alert, Info, Event).

### 3.9. Field Staff Application (`lib/staff_main.dart`)
- **Role Hierarchy:** Field Worker (`FIELD_WORKER`), Supervisor (`SUPERVISOR`), Department Officer (`OFFICER`).
- **Secure Provisioning:** Created exclusively server-side via Supabase Edge Function (`admin-create-staff`).
- **On-Duty Shift Management:** Dynamic duty toggle with real-time availability synchronization.
- **Task Resolution Engine (In-Progress):** Direct queue of assigned grievances with location coordinates, distance validation via Haversine RPC, before/after evidence photos, and resolution milestone submission.


---

## 4. Non-Functional Requirements (NFR)

| Domain | Requirement | Standard / Implementation |
| :--- | :--- | :--- |
| **Security & Privacy** | Zero secret keys in client bundle; Row-Level Security (RLS) on all tables; private bucket object paths (`<uid>/...`); SQL injection protection via parameterized RPCs. | Supabase Auth + RLS + Publishable key only. |
| **Performance** | Sub-300ms route transitions; image compression before upload; lazy loading and pagination on large list views (50 items/batch). | Flutter ahead-of-time (AOT) compilation; memory-efficient list views. |
| **Offline Resilience** | App-private JSON cache scoped to `cachedUserId` for viewing previously loaded requests during temporary network drops. | `LocalAppRepository` + `JsonFileStore`. |
| **Accessibility & UX** | Minimum touch targets of 48dp; high-contrast typography; semantic labels for screen readers; responsive multi-screen layouts. | Flutter Material 3 + `AppSpacing.minTouchTarget`. |
| **Reliability** | Atomic transactional rollback on upload/submission failure; zero unhandled async errors. | PostgREST RPCs + structured Dart try-catch blocks. |

---

## 5. Success Metrics & Key Performance Indicators (KPIs)

1. **Complaint Resolution Time:** Track mean time to resolution (MTTR) across all 10 civic departments.
2. **Vendor Onboarding Cycle:** Reduce average vendor license processing from weeks to under 5 business days.
3. **Application Stability:** Zero fatal crashes (0.00% crash rate); graceful offline detection and user error recovery.
4. **Citizen Engagement:** High proportion of self-service complaint tracking and bilingual usage in Nagpur.
