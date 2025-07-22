# Flutter/R8-specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.android.**  { *; }
-keep class io.flutter.embedding.engine.**  { *; }
-keep class io.flutter.plugin.common.**  { *; }

# Stripe rules
-keep class com.stripe.android.pushProvisioning.** { *; }

# Google Play Core rules
-keep class com.google.android.play.core.** { *; }
