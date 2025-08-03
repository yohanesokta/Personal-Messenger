# Flutter related
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.plugin.** { *; }

# Socket.IO
-keep class io.socket.** { *; }
-dontwarn io.socket.**
-keep class org.webrtc.** { *; }

# JSON
-keep class org.json.** { *; }

# Provider / SharedPreferences / Background service
-keep class android.content.SharedPreferences { *; }
-keep class android.app.Service { *; }
-keep class androidx.lifecycle.** { *; }

# Prevent obfuscating contextService if needed
-keep class com.yohaneschelin.secret.context.ContextService { *; }

# Optional: if you use reflection or getClass().getName()
-keepattributes *Annotation*
-keepattributes *Annotation*
-keep class * extends java.lang.annotation.Annotation { *; }


-dontwarn javax.lang.model.**
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

