#https://developer.android.com/studio/build/multidex
#ActivityTrimmerLayoutBinding
-keep public class * extends android.databinding.ViewDataBinding {
 *;
}

-keep public class com.creedon.reactlibrary.videotrimmer.databinding.* {*;}
#databinding
-dontwarn android.databinding.**
-keep class android.databinding.** { *; }
-keep class android.databinding.annotationprocessor.** { *; }



