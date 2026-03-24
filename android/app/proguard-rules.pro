# ML Kit Rules to prevent R8/ProGuard from stripping required classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
