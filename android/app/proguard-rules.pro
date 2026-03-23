# Facebook Ads (Meta Audience Network) ProGuard Rules
# These rules resolve the "Missing classes detected while running R8" errors
-dontwarn com.facebook.infer.annotation.**
-keep class com.facebook.ads.** { *; }

# Flutter Wrapper for Meta
-dontwarn com.google.ads.mediation.facebook.**
-keep class com.google.ads.mediation.facebook.** { *; }

# General Mediation Rules
-dontwarn com.google.ads.mediation.**
-keep class com.google.ads.mediation.** { *; }

# Unity Ads
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.ads.**
-dontwarn com.unity3d.services.**

# IronSource
-keep class com.ironsource.mediationsdk.** { *; }
-keep class com.ironsource.adapters.** { *; }
-keep class com.ironsource.unity.android.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class com.ironsource.sdk.controller.IronSourceWebView$JSInterface {
    public *;
}
-dontwarn com.ironsource.**
-dontwarn com.google.ads.mediation.ironsource.**

