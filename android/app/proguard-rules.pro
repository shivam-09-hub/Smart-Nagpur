# Flutter ProGuard Rules for Production Release
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Suppress harmless warnings from Flutter embedding & AndroidX
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.gms.**
-dontwarn androidx.**

# Preserve annotations and type reflection signatures
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
