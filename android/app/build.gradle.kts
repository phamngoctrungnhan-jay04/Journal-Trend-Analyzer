plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.prm393.journal_trend_analyzer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.prm393.journal_trend_analyzer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Bắt buộc cho Patrol E2E test (patrol_tests/) - patrol không tự
        // apply runner này qua Flutter plugin registration như các package
        // khác, cần khai báo thủ công theo docs chính thức.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    // Bắt buộc chạy Orchestrator: patrol (4.7.1) + patrol_cli (4.5.1) có bug
    // đã xác minh - khi 1 file test có từ 2 patrolTest() trở lên, request
    // runDartTest thứ 2 trong CÙNG tiến trình app bị lỗi
    // "PatrolAppServiceClientException: Invalid response 500" phía native,
    // dù bản thân test đó chạy đúng ở phía Dart (thấy qua PatrolBinding log:
    // "... but it was not requested, so its status will not be reported back
    // to the native side"). Orchestrator chạy mỗi test trong 1 tiến trình
    // app riêng biệt nên né được bug này hoàn toàn.
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

flutter {
    source = "../.."
}
