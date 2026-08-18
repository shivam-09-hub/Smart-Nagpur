# 🏛️ Smart Nagpur Admin Web ("NMC Command")

**Smart Nagpur Admin Web** is the official administrative web application for the Nagpur Municipal Corporation (NMC) civic grievance and field operations system.

It coexists independently with the **NMC Command** Android APK, connecting to the **exact same Supabase backend** without modifying or duplicating database tables or security policies.

---

## ⚡ Technology Stack

* **Structure:** Semantic HTML5
* **Styling:** Vanilla CSS3 (Custom design system, high-density desktop command center, responsive grid)
* **Logic:** Vanilla JavaScript (ES6+ modular architecture, Native Browser APIs)
* **Backend Client:** Supabase JavaScript Client (`@supabase/supabase-js` v2)
* **Zero build step required:** Pure web standards, runs instantly on any static file server or CDN.

---

## 🚀 Quick Start & Local Hosting

### Option 1: Using Python built-in HTTP server
```bash
cd smart-nagpur-admin-web
python -m http.server 8080
```
Open [http://localhost:8080](http://localhost:8080) in your browser.

### Option 2: Using Node.js `npx serve` or `npx http-server`
```bash
cd smart-nagpur-admin-web
npx serve .
```

### Option 3: Using VS Code Live Server
Right-click on `index.html` or `login.html` and select **"Open with Live Server"**.

---

## 🔐 Security & Role-Based Access Control

1. **Zero Secret Keys:** Uses only the public frontend Anon key (`SUPABASE_ANON_KEY`). Never exposes `SUPABASE_SERVICE_ROLE_KEY`.
2. **Server-Enforced Authorization:** Every data query, assignment mutation, and review action is protected by PostgreSQL Row Level Security (RLS) and `SECURITY DEFINER` database RPC functions.
3. **Admin Verification:** On sign-in, the account is validated against `public.admin_profiles` to verify `is_active = true` and retrieve specific role permissions.
4. **Time-Limited Storage:** Private photo and evidence storage buckets (`complaint-evidence`, `complaint-photos`, `vendor-documents`) are accessed exclusively via temporary signed URLs.

---

## 📱 Page & Feature Directory

| Route / File | Feature Name | Description |
| :--- | :--- | :--- |
| `login.html` | **Admin Authentication** | Secure email/password login and session initiation |
| `#dashboard` | **Operations Command Center** | Real-time metrics, live status donut chart, department breakdown |
| `#complaints` | **Complaints Management** | Filterable, searchable table of all reported civic complaints |
| `#complaint-details/:id` | **Complaint Details & Timeline** | Detailed breakdown, citizen info, map pin, photo lightbox |
| `#assignments` | **Task Assignment Tracking** | Multi-department work order tracking across 7 lifecycle states |
| `#verification` | **Verification Queue** | Dedicated queue of completed field tasks awaiting review |
| `#evidence/:id` | **Evidence Review Inspector** | Side-by-side Before/After photo comparison, GPS accuracy, Approve & Resolve / Request Rework actions |
| `#staff` | **Field Staff Roster** | Staff directory with department/role filters and **Staff Provisioning Modal** |
| `#staff-workload` | **Staff Workload Monitor** | Real-time technician capacity and active task load |
| `#departments` | **Municipal Departments** | 8 Municipal division overview and complaint distribution |
| `#vendors` | **Vendor Permitting** | Street vendor application review, document inspection, approval/rejection |
| `#analytics` | **Analytics & Reports** | Service distribution charts and monthly SLA performance aggregator |
| `#settings` | **Settings & Security** | Administrator profile info, password updates, and system health |

---

## 🏛️ Coexistence with Android APKs

| Application | Platform | Target Audience | Source Location |
| :--- | :--- | :--- | :--- |
| **NGP Seva** | Android APK | Citizens of Nagpur | `lib/` (Flutter flavor: `citizen`) |
| **NMC FieldForce** | Android APK | Field Technicians & Supervisors | `lib/` (Flutter flavor: `staff`) |
| **NMC Command (APK)** | Android APK | Municipal Administrators | `lib/` (Flutter flavor: `admin`) |
| **NMC Command (Web)** | Web App (HTML/CSS/JS) | Municipal Command Center Officers | `smart-nagpur-admin-web/` |
