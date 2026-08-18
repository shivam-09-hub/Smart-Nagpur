# Build Flavors & Production Release Guide — Smart Nagpur

This guide details the build configuration, product flavors, and exact commands for generating production release APKs and App Bundles (`.aab`) for the **Citizen**, **Admin**, and **Staff** applications from the unified Smart Nagpur codebase.

---

## 1. Flavor & Application Matrix

| Application | Flavor Name | Application ID (Package Name) | App Display Name | Target APK Name | Entry Point |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Citizen App** | `citizen` | `com.smartnagpur.citizen` | **NGP Seva** | `NGP_Seva.apk` | `lib/main.dart` |
| **Admin App** | `admin` | `com.smartnagpur.admin` | **NMC Command** | `NMC_Command.apk` | `lib/admin_main.dart` |
| **Staff App** | `staff` | `com.smartnagpur.staff` | **NMC FieldForce** | `NMC_FieldForce.apk` | `lib/staff_main.dart` |

---

## 2. Production Release Commands

### A. Production Release APKs

```bash
# 1. Citizen Release APK (NGP Seva)
flutter build apk --release --flavor citizen -t lib/main.dart --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y

# 2. Admin Release APK (NMC Command)
flutter build apk --release --flavor admin -t lib/admin_main.dart --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y

# 3. Staff Release APK (NMC FieldForce)
flutter build apk --release --flavor staff -t lib/staff_main.dart --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y
```

#### Output Artifact Paths:
- Citizen APK: `build/app/outputs/flutter-apk/app-citizen-release.apk` (`APKs/NGP_Seva.apk`)
- Admin APK: `build/app/outputs/flutter-apk/app-admin-release.apk` (`APKs/NMC_Command.apk`)
- Staff APK: `build/app/outputs/flutter-apk/app-staff-release.apk` (`APKs/NMC_FieldForce.apk`)

---

### B. Google Play Store Production App Bundles (`.aab`)

```bash
# 1. Citizen App Bundle
flutter build appbundle --release --flavor citizen -t lib/main.dart --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y

# 2. Admin App Bundle
flutter build appbundle --release --flavor admin -t lib/admin_main.dart --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y

# 3. Staff App Bundle
flutter build appbundle --release --flavor staff -t lib/staff_main.dart --no-pub \
  --dart-define=SUPABASE_URL=https://hcpcycfvupjuklhcaxzg.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y
```

#### Output Artifact Paths:
- Citizen AAB: `build/app/outputs/bundle/citizenRelease/app-citizen-release.aab`
- Admin AAB: `build/app/outputs/bundle/adminRelease/app-admin-release.aab`
- Staff AAB: `build/app/outputs/bundle/staffRelease/app-staff-release.aab`

---

## 3. Production Keystore Signing Configuration

To sign with official municipal production keys, create `android/key.properties`:

```properties
storeFile=../smartnagpur-release.jks
storePassword=your_keystore_password
keyAlias=smartnagpur
keyPassword=your_key_password
```

> **Note:** If `android/key.properties` is omitted, the build script safely falls back to standard debug signing for local test builds without failing.

---

## 4. Deep-Link Redirect Allowlist (Supabase Auth)

Ensure the following 3 redirect URLs are added to **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs**:

```
com.smartnagpur.citizen://login-callback/
com.smartnagpur.admin://login-callback/
com.smartnagpur.staff://login-callback/
```
