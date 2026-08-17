# Build Flavors Setup Guide

This guide explains how to set up and configure build flavors for the Smart Nagpur application to support both citizen and admin APKs with different package IDs.

## Overview

Build flavors allow you to create multiple versions of your app from the same codebase. For Smart Nagpur:

- **Citizen Flavor**: `com.smartnagpur.citizen` - User-facing application
- **Admin Flavor**: `com.smartnagpur.admin` - Admin panel application

## Setup Instructions

### 1. Update Android Build Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 24
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    flavorDimensions "app"

    productFlavors {
        citizen {
            dimension "app"
            applicationId "com.smartnagpur.citizen"
            resValue "string", "app_name", "Smart Nagpur"
        }

        admin {
            dimension "app"
            applicationId "com.smartnagpur.admin"
            resValue "string", "app_name", "Smart Nagpur Admin"
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
        debug {
            signingConfig signingConfigs.debug
        }
    }

    lintOptions {
        disable 'MissingDimensionality'
    }
}
```

### 2. Update Android Manifest

The manifest is already shared and supports both apps. The package name is determined by the build.gradle configuration above.

### 3. Configure Deep Links for Admin

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.smartnagpur.citizen">

    <!-- Citizen app activities -->
    <activity
        android:name=".MainActivity"
        android:exported="true"
        android:launchMode="singleTop"
        android:theme="@style/LaunchTheme"
        android:windowSoftInputMode="adjustResize">
        <!-- Citizen auth deep link -->
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="com.smartnagpur.citizen" android:host="login-callback" />
        </intent-filter>
    </activity>
</manifest>
```

For admin flavor, create `android/app/src/admin/AndroidManifest.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.smartnagpur.admin">

    <application>
        <!-- Admin app activities -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:windowSoftInputMode="adjustResize">
            <!-- Admin auth deep link -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="com.smartnagpur.admin" android:host="login-callback" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 4. Create Flavor-Specific Dart Entry Points

Already configured:
- Citizen: `lib/main.dart`
- Admin: `lib/admin_main.dart`

### 5. Update Supabase Redirect URLs

In Supabase Dashboard → Authentication → URL Configuration → Redirect URLs, add both:

```
com.smartnagpur.citizen://login-callback/
com.smartnagpur.admin://login-callback/
```

## Building APKs

### Build Citizen APK

**Debug:**
```bash
flutter clean
flutter pub get
flutter build apk --flavor citizen -t lib/main.dart
```

Output: `build/app/outputs/flutter-apk/app-citizen-debug.apk`

**Release:**
```bash
flutter build apk --release --flavor citizen -t lib/main.dart --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key
```

Output: `build/app/outputs/flutter-apk/app-citizen-release.apk`

### Build Admin APK

**Debug:**
```bash
flutter clean
flutter pub get
flutter build apk --flavor admin -t lib/admin_main.dart
```

Output: `build/app/outputs/flutter-apk/app-admin-debug.apk`

**Release:**
```bash
flutter build apk --release --flavor admin -t lib/admin_main.dart --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key
```

Output: `build/app/outputs/flutter-apk/app-admin-release.apk`

## Building App Bundles for Play Store

### Citizen App Bundle

```bash
flutter build appbundle --release \
  --flavor citizen \
  -t lib/main.dart \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key
```

Output: `build/app/outputs/bundle/citizenRelease/app-citizen-release.aab`

### Admin App Bundle

```bash
flutter build appbundle --release \
  --flavor admin \
  -t lib/admin_main.dart \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key
```

Output: `build/app/outputs/bundle/adminRelease/app-admin-release.aab`

## Running Apps

### Run Citizen App

```bash
flutter run --flavor citizen -t lib/main.dart
```

### Run Admin App

```bash
flutter run --flavor admin -t lib/admin_main.dart
```

## Gradle Build Commands

If you prefer to use gradle directly:

```bash
# Build citizen APK
./gradlew assembleAdminRelease -PbuildName=citizen

# Build admin APK
./gradlew assembleAdminRelease

# Build citizen bundle
./gradlew bundleCitizenRelease

# Build admin bundle
./gradlew bundleAdminRelease
```

## Testing

### Test citizen app
```bash
flutter test --coverage -t lib/main.dart
```

### Test admin app
```bash
flutter test --coverage -t lib/admin_main.dart
```

### Test both
```bash
flutter test --coverage
```

## Signing Configuration

Create `android/key.properties`:

```properties
storeFile=../keystore.jks
storePassword=your_store_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

Update `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

Generate keystore if not exists:

```bash
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias smartnagpur
```

## Play Store Setup

### Create Separate Apps

1. **Citizen App**
   - Package Name: `com.smartnagpur.citizen`
   - Title: "Smart Nagpur"
   - Description: User app for reporting civic issues

2. **Admin App**
   - Package Name: `com.smartnagpur.admin`
   - Title: "Smart Nagpur Admin"
   - Description: Admin panel for reviewing complaints and managing city services
   - Access Level: Restricted to verified admin accounts

## Troubleshooting

### Issue: "No resource found" for app_name
**Solution**: Ensure `resValue` is set in each flavor's configuration in build.gradle

### Issue: Wrong package name in build
**Solution**: Verify `applicationId` is correctly set in each flavor

### Issue: Deep link not working
**Solution**: 
1. Check Supabase redirect URLs contain exact match
2. Verify `android:scheme` matches package name
3. Ensure deep link is added to correct AndroidManifest.xml file

### Issue: Both apps installing same ID
**Solution**: Clear build cache and ensure flavors are properly configured
```bash
flutter clean
./gradlew clean
rm -rf build/
rm -rf .dart_tool/
```

### Issue: Supabase initialization fails in admin
**Solution**: Ensure admin_main.dart passes correct Supabase config to Supabase.initialize()

## Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Build APKs

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release --flavor citizen -t lib/main.dart
      - run: flutter build apk --release --flavor admin -t lib/admin_main.dart
      - uses: actions/upload-artifact@v3
        with:
          name: apks
          path: build/app/outputs/flutter-apk/
```

## Documentation

For more information:
- [Flutter Flavors Documentation](https://flutter.dev/docs/deployment/flavors)
- [Android Build Variants](https://developer.android.com/build/build-variants)
- [Play Store Distribution](https://developer.android.com/distribute)
