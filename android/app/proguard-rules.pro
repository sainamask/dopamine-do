# flutter_local_notifications: the plugin uses reflection on these classes
# to deserialize scheduled notification state. Without this rule, R8
# silently breaks alarms that were scheduled before an app upgrade.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Gson is bundled by flutter_local_notifications; preserve its
# reflective access to model fields.
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements java.lang.reflect.Type
-keepattributes Signature
-keepattributes *Annotation*

# audioplayers: keep its native bridges.
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# flutter_tts.
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# speech_to_text.
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# permission_handler.
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Flutter engine.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
