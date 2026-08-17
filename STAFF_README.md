# Smart Nagpur Field Staff Application

This is the on-ground field technician and supervisor mobile application for the Smart Nagpur municipal platform. The Staff app enables municipal workers to receive assigned complaints, navigate to grievance sites with turn-by-turn GPS guidance, capture on-site geo-verified Before/After evidence, and resolve civic issues.

---

## 1. Key Features

### Shift & Duty Management
- Live on-duty / off-duty toggle updating `staff_profiles(is_on_duty, last_active_at)`.
- Technician profile overview displaying assigned municipal Department (Solid Waste, Water, Roads, Electricity, etc.) and Zone.

### Realtime Task Consumption
- Live debounced sync receiving assignments dispatched by Municipal Administrators.
- Priority-ordered task feed (`urgent` $\to$ `high` $\to$ `medium` $\to$ `low`).
- Filter chips: All, Assigned, Accepted, In Progress, Completed, Rework.

### Field Navigation & Location Engine
- Turn-by-turn navigation launcher connecting directly to Google Maps / `geo:` navigation intents.
- 10-state GPS failure handler (detecting mock GPS, stale fixes, low accuracy, disabled location, and permission states).
- 1-tap coordinate clipboard copy.

### Geo-Verified Evidence & Resolution
- Server-authoritative Haversine proximity verification ($\le 100\text{m}$ radius, GPS accuracy $\le 50\text{m}$).
- On-site **Before-Work Photo** capture (required prior to work commencement).
- On-site **After-Work Photo** capture (required for task completion).
- Optional **Inspection PDF Report** document upload.
- Context-aware state machine (`acceptTask` $\to$ `startTask` $\to$ `uploadEvidence` $\to$ `completeTask`).

### Rework Handling & Immutability
- Receives supervisor rework directives with detailed rework notes.
- Completed tasks become strictly immutable to prevent accidental tampering.

---

## 2. Staff Roles & Departments

### Staff Roles
- **Field Worker (`FIELD_WORKER`):** Assigned on-ground repair tasks, captures GPS evidence, completes work.
- **Supervisor (`SUPERVISOR`):** Reviews departmental queue and coordinates technician dispatches.
- **Officer (`OFFICER`):** Departmental administrative authority.

### Supported Municipal Departments
- `SOLID_WASTE` (Garbage, cleanliness, sweeping)
- `WATER_SUPPLY` (Pipe leaks, contamination, pressure issues)
- `ROADS` (Potholes, resurfacing, paving)
- `STREET_LIGHTING` (Broken lights, flickering poles)
- `DRAINAGE` (Blocked drains, sewage overflows)
- `HEALTH` (Sanitation, pest control)
- `GARDEN` (Tree pruning, park maintenance)
- `TRAFFIC` (Signals, road signs, parking)
- `GENERAL` (Civic grievances & other)

---

## 3. Building the Staff APK

### Debug Mode (Local Testing)
```bash
flutter run -t lib/staff_main.dart
```

### Production Release APK (Using Flavors)
```bash
flutter build apk --release --flavor staff -t lib/staff_main.dart --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y
```

**Output Artifact:** `build/app/outputs/flutter-apk/app-staff-release.apk`

---

## 4. Security & Isolation

1. **Self-Escalation Protection:** Database trigger `check_staff_profile_update_integrity` prevents field workers from altering `role`, `department`, `employee_id`, or `is_active`.
2. **Private Storage:** Field photos and inspection PDFs are saved to the private `complaint-evidence` storage bucket with RLS-scoped path prefixes and 300s short-lived signed URLs.
3. **Task Isolation:** Field workers can only view and update tasks assigned to their authenticated user ID.
