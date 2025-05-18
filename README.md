# project2

A new Flutter project.

Is there anything else you'd like me to fix or improve in the project?
困難：
1. 要猜測自己有可能如何被扣分
2. Dart SDK太舊(build error)=>更新了
3. 我的Kotlin Version 也太舊
4. 我的Gradle也很舊
5. 新版的gradle文件位置變了，gradle-wrapper.properties找了三分鐘



SDK LOG: ---------------------------------------------------------------------------------
Downloading android-arm-profile/windows-x64 tools...
Downloading android-arm-release/windows-x64 tools...
Downloading android-arm64-profile/windows-x64 tools...
Downloading android-arm64-release/windows-x64 tools...
Downloading android-x64-profile/windows-x64 tools...
Downloading android-x64-release/windows-x64 tools...
Launching lib\main.dart on AOSP on IA Emulator in debug mode...
Support for Android x86 targets will be removed in the next stable release after 3.27. See https://github.com/flutter/flutter/issues/157543 for details.
Running Gradle task 'assembleDebug'...
Warning: Flutter support for your project's Android Gradle Plugin version (7.3.0) will soon be dropped. Please upgrade your Android Gradle Plugin version to a version of at least 7.3.1 soon.
Alternatively, use the flag "--android-skip-build-dependency-validation" to bypass this check.

Potential fix: Your project's AGP version is typically defined in the plugins block of the `settings.gradle` file (C:\Users\user\AndroidStudioProjects\project2\android/settings.gradle), by a plugin with the id of com.android.application.
If you don't see a plugins block, your project was likely created with an older template version. In this case it is most likely defined in the top-level build.gradle file (C:\Users\user\AndroidStudioProjects\project2\android/build.gradle) by the following line in the dependencies block of the buildscript: "classpath 'com.android.tools.build:gradle:<version>'".

Warning: Flutter support for your project's Kotlin version (1.7.10) will soon be dropped. Please upgrade your Kotlin version to a version of at least 1.8.10 soon.
Alternatively, use the flag "--android-skip-build-dependency-validation" to bypass this check.

Potential fix: Your project's KGP version is typically defined in the plugins block of the `settings.gradle` file (C:\Users\user\AndroidStudioProjects\project2\android/settings.gradle), by a plugin with the id of org.jetbrains.kotlin.android.
If you don't see a plugins block, your project was likely created with an older template version, in which case it is most likely defined in the top-level build.gradle file (C:\Users\user\AndroidStudioProjects\project2\android/build.gradle) by the ext.kotlin_version property.

Checking the license for package NDK (Side by side) 26.3.11579264 in C:\Users\user\AppData\Local\Android\sdk\licenses
License for package NDK (Side by side) 26.3.11579264 accepted.
Preparing "Install NDK (Side by side) 26.3.11579264 (revision: 26.3.11579264)".
"Install NDK (Side by side) 26.3.11579264 (revision: 26.3.11579264)" ready.
Installing NDK (Side by side) 26.3.11579264 in C:\Users\user\AppData\Local\Android\sdk\ndk\26.3.11579264
"Install NDK (Side by side) 26.3.11579264 (revision: 26.3.11579264)" complete.
"Install NDK (Side by side) 26.3.11579264 (revision: 26.3.11579264)" finished.
Checking the license for package CMake 3.18.1 in C:\Users\user\AppData\Local\Android\sdk\licenses
License for package CMake 3.18.1 accepted.
Preparing "Install CMake 3.18.1 (revision: 3.18.1)".
"Install CMake 3.18.1 (revision: 3.18.1)" ready.
Installing CMake 3.18.1 in C:\Users\user\AppData\Local\Android\sdk\cmake\3.18.1
"Install CMake 3.18.1 (revision: 3.18.1)" complete.
"Install CMake 3.18.1 (revision: 3.18.1)" finished.

FAILURE: Build failed with an exception.

* What went wrong:
  Execution failed for task ':app:processDebugResources'.
> A failure occurred while executing com.android.build.gradle.internal.res.LinkApplicationAndroidResourcesTask$TaskAction
> Android resource linking failed
aapt2.exe E 05-18 00:50:55 19944  7160 LoadedArsc.cpp:94] RES_TABLE_TYPE_TYPE entry offsets overlap actual entry data.
aapt2.exe E 05-18 00:50:55 19944  7160 ApkAssets.cpp:149] Failed to load resources table in APK 'C:\Users\user\AppData\Local\Android\sdk\platforms\android-35\android.jar'.
error: failed to load include path C:\Users\user\AppData\Local\Android\sdk\platforms\android-35\android.jar.


* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.

* Get more help at https://help.gradle.org

BUILD FAILED in 2m 47s

┌─ Flutter Fix ────────────────────────────────────────────────────────────────────────────────────┐
│ [!] Using compileSdk 35 requires Android Gradle Plugin (AGP) 8.1.0 or higher.                    │
│  Please upgrade to a newer AGP version. The version of AGP that your project uses is likely      │
│  defined in:                                                                                     │
│ C:\Users\user\AndroidStudioProjects\project2\android\settings.gradle,                            │
│ in the 'plugins' closure (by the number following "com.android.application").                    │
│  Alternatively, if your project was created with an older version of the templates, it is likely │
│ in the buildscript.dependencies closure of the top-level build.gradle:                           │
│ C:\Users\user\AndroidStudioProjects\project2\android\build.gradle,                               │
│ as the number following "com.android.tools.build:gradle:".                                       │
│                                                                                                  │
│  Finally, if you have a strong reason to avoid upgrading AGP, you can temporarily lower the      │
│  compileSdk version in the following file:                                                       │
│ C:\Users\user\AndroidStudioProjects\project2\android\app\build.gradle                            │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
Error: Gradle task assembleDebug failed with exit code 1