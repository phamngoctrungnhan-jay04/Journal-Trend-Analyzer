pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    // Bắt buộc cho firebase_crashlytics - package Dart không tự apply plugin
    // này, cần khai báo thủ công (đã verify qua doc chính thức + source
    // build.gradle của package trên GitHub, không suy đoán).
    id("com.google.firebase.crashlytics") version "3.0.7" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
