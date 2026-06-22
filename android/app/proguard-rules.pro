# R8/ProGuard keep rules for the Travel Mate release build.
#
# Background: R8 used to strip/rename classes that the QR camera stack reaches by reflection, which
# crashed the scanner at runtime with an NPE on obfuscated names. These keep rules let R8 run (so the
# bundle is shrunk and a mapping.txt is produced) while leaving the camera stack and the optional
# Play Core classes intact.

# --- mobile_scanner: ML Kit barcode scanning + CameraX ---
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-dontwarn com.google.mlkit.**
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-keep class dev.steenbakker.mobile_scanner.** { *; }

# ML Kit loads its model/optional modules by reflection; don't let R8 remove them.
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.android.gms.vision.**

# --- in_app_update references Play Core / Play App-Update, which may be absent at compile time ---
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- Flutter deferred-components / Play split-install stubs ---
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
