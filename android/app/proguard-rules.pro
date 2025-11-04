# Flutter Core - Keep all Flutter framework classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Prevent stripping Flutter GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Location Package - Keep all location classes and services
-keep class com.lyokone.location.** { *; }
-keep interface com.lyokone.location.** { *; }
-keep class com.lyokone.location.FlutterLocationService { *; }
-keep class com.lyokone.location.LocationPlugin { *; }
-keep class com.lyokone.location.MethodCallHandlerImpl { *; }
-keep class com.lyokone.location.StreamHandlerImpl { *; }

# Location Platform Interface
-keep class io.flutter.plugins.location.** { *; }

# Permission Handler Plugin
-keep class com.baseflow.permissionhandler.** { *; }

# Audio Recording Plugins
-keep class com.llfbandit.record.** { *; }
-keep class com.llfbandit.record.RecordPlugin { *; }

# Audio Players
-keep class xyz.luan.audioplayers.** { *; }
-keep class xyz.luan.audioplayers.AudioplayersPlugin { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.just_audio.JustAudioPlugin { *; }

# Google Play Core Services (for deferred components and tasks)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Firebase Plugins
-keep class io.flutter.plugins.firebase.** { *; }
-keep class com.google.firebase.** { *; }

# Image Picker Plugin
-keep class io.flutter.plugins.imagepicker.** { *; }

# Path Provider Plugin
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences Plugin
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# URL Launcher Plugin
-keep class io.flutter.plugins.urllauncher.** { *; }

# Device Info Plugin
-keep class io.flutter.plugins.deviceinfo.** { *; }

# Package Info Plugin
-keep class io.flutter.plugins.packageinfo.** { *; }

# Network Info Plugin
-keep class io.flutter.plugins.connectivity.** { *; }

# File Picker Plugin
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Google Maps Plugin
-keep class io.flutter.plugins.googlemaps.** { *; }

# Video Player Plugin
-keep class io.flutter.plugins.videoplayer.** { *; }

# WebView Plugin
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Local Notifications Plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep all plugin interfaces and implementations
-keep class * implements io.flutter.plugin.common.PluginRegistry$Registrar { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }

# Keep all method channels
-keep class * extends io.flutter.plugin.common.MethodChannel { *; }
-keep class * extends io.flutter.plugin.common.EventChannel { *; }

# Keep all native method implementations
-keepclassmembers class * {
    @io.flutter.plugin.common.PluginRegistry.Registrar *;
}

# Prevent obfuscation of classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Generated missing rules from R8 (suppress warnings for missing classes)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Enhanced size optimization rules
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Remove unused resources
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Remove debug information
-keepattributes !LocalVariableTable,!LocalVariableTypeTable

# Aggressive obfuscation for size reduction
-repackageclasses ''
-allowaccessmodification
