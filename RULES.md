# Development Rules & AI Boundaries — Smart Nagpur

This document outlines the authoritative rules, architectural constraints, security invariants, library usage policies, and error handling guidelines for **Smart Nagpur**. All human developers and AI assistants working on this codebase MUST strictly adhere to these rules.

---

## 1. Core Architectural & Code Conventions

### 1.1. Dart & Flutter Standards
- **Null Safety:** Strict null-safety is mandatory across 100% of the codebase. Never use untyped `dynamic` unless interacting directly with raw JSON deserialization.
- **Lint Compliance:** Code must pass `flutter analyze` with zero warnings and zero errors. Respect rules defined in `analysis_options.yaml` (using `package:flutter_lints`).
- **Immutability:** Domain entities and UI configuration models must be immutable (`@immutable` or `const` constructors) with `toJson()`, `fromJson()`, and `copyWith()` methods.
- **Layer Separation:**
  - `lib/domain`: Pure Dart only. NEVER import `package:flutter/material.dart` or `package:supabase_flutter/supabase_flutter.dart`.
  - `lib/data`: Encapsulates all backend APIs, data transformations, and storage calls.
  - `lib/state`: Coordinates presentation logic via `ChangeNotifier`. No direct HTTP or database queries outside of gateway interfaces.
  - `lib/features`: Focuses on presentation. Widgets MUST interact with the backend exclusively via state controllers or injected gateways.

---

## 2. Library Usage Policy: What to Use vs. What to Avoid

### 2.1. Approved Libraries & Tools
| Allowed Library | Approved Purpose |
| :--- | :--- |
| `supabase_flutter: ^2.16.0` | Authentication, PostgreSQL queries, Storage file uploads, and RPC calls (data layer only). |
| `geolocator: ^14.0.3` | Foreground GPS coordinate detection behind `DeviceLocationService`. |
| `image_picker: ^1.2.3` | Camera and gallery photo selection behind `DeviceMediaPickerService`. |
| `file_picker: ^12.0.0` | Document picking (PDF/images) behind `DeviceDocumentPickerService`. |
| `path_provider: ^2.1.6` | Resolving app-private storage directories for cache and temp files. |
| `intl: ^0.20.2` | Date formatting, number localization, and time utilities. |
| `uuid: ^4.6.0` | Generating collision-resistant UUIDs for storage object keys. |
| `cupertino_icons: ^1.0.8` | Standardized icon assets alongside Material Design icons. |

### 2.2. Prohibited Libraries & Patterns
- **DO NOT** introduce heavy third-party state management libraries (e.g., `flutter_bloc`, `riverpod`, `mobx`, `get_it`, `getx`). State is unified using Flutter's built-in `ChangeNotifier` and `ListenableBuilder`.
- **DO NOT** use `shared_preferences` for storing sensitive tokens or large domain data. Use the established `JsonFileStore` / `LocalAppRepository` pattern.
- **DO NOT** add raw HTTP clients (`dio`, `http`) to communicate with Supabase. Always use the official `supabase_flutter` client through the abstract gateway layer.
- **DO NOT** introduce external map SDKs that require non-free proprietary API keys without explicit architectural approval. Use `DevelopmentMap` as the current pin-adjust fallback.

---

## 3. Security Invariants (CRITICAL)

### 3.1. Credential Security
- **NEVER** embed, hardcode, or commit a Supabase `service_role` secret key, database password, or administrative JWT into the Flutter application.
- The client application MUST only receive a public `SUPABASE_PUBLISHABLE_KEY` (or legacy `anon` key) validated through `SupabaseConfig.validate()`.
- Admin permissions are enforced strictly on the PostgreSQL backend using Row-Level Security (RLS) policies and `admin_profiles` lookups, never through client-side overrides.

### 3.2. File Upload & Storage Rules
- All file uploads to Supabase Storage must use private buckets (`complaint-photos`, `vendor-documents`).
- Object paths MUST follow the owner-prefixed pattern: `<auth.uid()>/<upload-group UUID>/<file UUID>.<extension>`.
- File validation invariants:
  - **Complaint Photos:** Allowed extensions: `.jpg`, `.jpeg`, `.png`, `.webp`. Maximum size: 10 MiB per image (up to 3 images).
  - **Vendor Documents:** Allowed extensions: `.pdf`, `.jpg`, `.jpeg`, `.png`. Maximum size: 10 MiB per document.
- If a submission RPC fails after files are uploaded, the newly uploaded objects should be cleaned up / rolled back.

### 3.3. Deep Link Security
- Deep links for authentication (`com.smartnagpur.citizen://login-callback/` and `com.smartnagpur.admin://login-callback/`) must be exact matches on the Supabase Redirect URLs allowlist, including the trailing slash.

---

## 4. State & Data Handling Rules

### 4.1. Local Cache Isolation
- The local JSON cache is **read-only offline fallback** and is strictly scoped to the authenticated `cachedUserId`.
- When a user logs out or switches accounts, all sensitive cached data (`_clearProtectedData()`) must be purged immediately.
- A persisted local boolean flag MUST NEVER be accepted as a valid authenticated session. Supabase Auth is the single source of truth for session validity.

### 4.2. Demo Mode Integrity
- Demo mode is an explicit local-only sandbox.
- When `isDemoMode == true`, the application MUST NOT transmit demo records, mock coordinates, or mock files to Supabase.
- Demo data MUST NOT pollute or overwrite cloud database tables.

### 4.3. Offline Mutations Policy
- Offline write queuing is intentionally **prohibited**. Creating complaints, submitting vendor applications, and editing profile details require a live Supabase connection to guarantee server-side validation and file persistence.

---

## 5. Error Handling & Resilience

### 5.1. UI Error Display
- Every async operation that can fail (network timeouts, auth errors, storage limits) must catch exceptions and populate user-friendly error messages in the state controller.
- Never crash the UI or display raw stack traces to the user. Present actionable error banners with a "Retry" button.

### 5.2. Graceful Degradation
- If GPS location permission is denied by the user, the app must gracefully fall back to manual address entry and interactive map pin placement without throwing unhandled exceptions.
- If camera permissions are denied, the user must still be allowed to choose existing images from the gallery.

---

## 6. AI Agent Guidelines & Do's / Don'ts

### Do's:
1. **Always run tests:** Execute `flutter test` after modifying any state, gateway, domain model, or screen to verify zero regressions.
2. **Follow Design Tokens:** Always reference colors, spacing, and typography from `lib/core/theme/app_tokens.dart` (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`). Never hardcode hex colors or arbitrary padding.
3. **Use Localization:** Wrap user-facing strings in `AppStrings.of(context).text(...)` or localized accessors in `lib/core/localization/app_strings.dart`.
4. **Preserve Comments & Structure:** Maintain docstrings, licensing notices, and file structure integrity.

### Don'ts:
1. **DON'T** modify generated files (`.dart_tool/`, `build/`, `*.lock`) manually.
2. **DON'T** change the database schema without adding an accompanying SQL migration under `supabase/migrations/` and updating the contract test `supabase/tests/schema_contract.sql`.
3. **DON'T** bypass the gateway interfaces to call Supabase directly from widgets.
4. **DON'T** remove or bypass test suites under `test/`.
