# Mapbox Navigation SDK ProGuard Rules
-dontwarn com.google.auto.value.**
-keep class com.google.auto.value.** { *; }

-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# Common Android Volley/OkHttp rules if needed
-dontwarn okio.**
-dontwarn com.squareup.okhttp.**
