# Implementation memory

## 2026-08-17

- Confirmed the supplied workspace was empty and contained no documentation or
  Stitch artifacts; user approved a greenfield build in this folder.
- Created one Android Flutter application with application ID
  `com.smartnagpur.citizen`.
- Added only the packages required for GPS, image selection, document selection,
  durable app-private storage, localization formatting, Supabase, and UUID-safe
  Storage object names.
- Implemented centralized theme/localization, repository boundaries, local JSON
  persistence, demo data, and reusable loading/empty/error components.
- Implemented splash, onboarding, Home, news, search, ten services, universal
  complaint flow, photo/GPS/development-map flow, My Requests, notifications,
  profile/settings, and vendor application/tracking flows.
- Replaced mock signed-in persistence with Supabase email/password Auth,
  Postgres, private Storage, owner-scoped data/file gateways, confirmation and
  password-recovery deep links, and an explicit local-only demo entry point.
- Added the idempotent Supabase migration, transactional complaint/vendor RPCs,
  Auth profile trigger, least-privilege grants, Row-Level Security and Storage
  policies, plus a schema contract test. The remote project still requires the
  authorized one-time SQL Editor deployment and the exact redirect allowlist
  entry `com.smartnagpur.citizen://login-callback/`.
- The Flutter client contains only a publishable key. A database password,
  secret key, or service-role key must never be embedded in the app; authorization
  is enforced by Supabase Auth, RLS, restricted grants, and owner-scoped RPCs.
- Onboarding, locale, and matching-user cloud reads use app-private local
  storage. Cached reads provide a temporary offline fallback, but cloud writes
  are not queued. Protected cached data is cleared on sign-out/user mismatch,
  and a local authentication flag is never accepted as a Supabase session.
- Demo records remain explicitly local-only. The Supabase project is not
  connected to an official municipal case-management system, so neither cloud
  nor demo submissions represent official municipal processing.
- Map provider decision remains deferred until an approved provider/configuration
  is supplied. `DevelopmentMap` is the current adjustable-pin fallback.
- Stitch visual validation remains pending because no Stitch artifact exists in
  the workspace.
- Installed and launched the original greenfield debug build on a physical Vivo
  V2142 running Android 14. A cold-start listener notification assertion found
  in the first device run was fixed by deferring initialization until after the
  first frame; the corrected build foregrounded with no Flutter, fatal, or app
  ANR log entry.
- Expanded regression coverage for configuration safety, cache isolation,
  cloud login/session hydration, email-confirmation registration, logout, and
  password recovery. At the Supabase integration checkpoint, `flutter analyze
  --no-pub` was clean, all 25 tests passed, and `flutter build apk --debug
  --no-pub` completed successfully.
