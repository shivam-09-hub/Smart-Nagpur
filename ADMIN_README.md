# Smart Nagpur Admin Application (NMC Command)

This is the administrative command center for the Smart Nagpur municipal platform (`flavor: admin` / `com.smartnagpur.admin`). The admin app enables authorized municipal officers to triage complaints, dispatch field technicians, verify on-site resolution evidence, review street vendor applications, manage user accounts, and broadcast city notifications.

---

## 1. Key Features

### Executive Dashboard & Live KPIs
- Real-time resolution rate and vendor permit approval metrics.
- Active complaint volume by municipal service category.
- Quick action cards linking to triage queues, operations, and broadcasts.

### Complaint Management & Field Staff Dispatching
- View all pending complaints with filters (department, priority, status).
- Detailed complaint review with GPS coordinates, address, and citizen photos.
- Assign grievances to active on-duty field workers with department validation.
- Live reassignment flow and supervisor directive notes.
- Categorized view across all 10 civic service domains.

### Field Operations & Verification Dashboard
- Single-roundtrip server-side aggregation (`get_admin_operations_dashboard`).
- Live Verification Queue tab displaying completed complaints awaiting inspection.
- Evidence inspection gallery with Before/After photos and inspection PDF download.
- GPS proximity ($\le 100\text{m}$) and accuracy ($\le 50\text{m}$) badge verification.
- Staff Workload tab tracking active technicians, on-duty status, and assigned tasks.
- Complaint & Assignment status breakdown chips with instant filter resets.
- 1-tap **Approve Resolution** and **Request Rework** actions.

### Vendor Application Management
- Review pending vendor applications and business classifications.
- View applicant details, vending zone selections, and uploaded KYC/FSSAI documents.
- Approve/reject applications with official administrative remarks.
- Track application status through the milestone timeline.

### Notification Management & Broadcasts
- Send broadcast notifications to all registered citizens.
- Send targeted notifications to specific users.
- Notification history, category-based categorization (Emergency, Alert, Info, Event).

### User Management & Staff Provisioning
- View registered citizens and audit account status.
- Suspend user accounts with mandatory reason logging; 1-tap account reactivation.
- Native staff account provisioning with auto-normalized auth tokens.

---

## 2. Admin Roles & Permissions

- **Super Admin (`superAdmin`):** Full system access, configuration, and staff provisioning.
- **Complaint Reviewer (`complaintReviewer`):** Review, assign, and verify complaints.
- **Vendor Reviewer (`vendorReviewer`):** Review and approve/reject vendor permits.
- **Report Viewer (`reportViewer`):** View analytics, metrics, and summary reports.
- **Notification Manager (`notificationManager`):** Send broadcasts and announcements.
- **User Manager (`userManager`):** Manage user accounts, suspensions, and staff accounts.

---

## 3. Building the Admin APK

### A. Split-per-ABI Release APK (Recommended)
```bash
flutter build apk --release --flavor admin -t lib/admin_main.dart --split-per-abi --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y
```
**Outputs:**
- `APKs/Admin/SmartNagpur_Admin_arm64-v8a.apk` (~22.6 MB)
- `APKs/Admin/SmartNagpur_Admin_armeabi-v7a.apk` (~20.4 MB)
- `APKs/Admin/SmartNagpur_Admin_x86_64.apk` (~24.0 MB)

### B. Universal Fat Release APK
```bash
flutter build apk --release --flavor admin -t lib/admin_main.dart --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y
```
**Output:** `APKs/NMC_Command.apk` (`build/app/outputs/flutter-apk/app-admin-release.apk`) (~57.3 MB)

---

## 4. Database Setup & Security

1. Ensure the admin migration has been applied: `supabase/migrations/202608180001_smart_nagpur_admin.sql`
2. Run `supabase/migrations/202608190001_smart_nagpur_staff.sql` for assignment & operations dashboard RPCs.
3. Ensure redirect URL is active: `com.smartnagpur.admin://login-callback/`
