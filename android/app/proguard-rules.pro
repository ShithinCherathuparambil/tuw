# Keep Geolocator plugin classes
-keep class com.baseflow.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
# Flutter core
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Baseflow (Geolocator & related)
-keep class com.baseflow.** { *; }

# Flutter Sound Record
-keep class com.josephcrowell.flutter_sound_record.** { *; }

# Google Play Core (SplitCompat, Deferred Components)
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Prevent stripping Flutter GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
