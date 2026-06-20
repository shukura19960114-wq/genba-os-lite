plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.genba_os_lite"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 本番化前に独自のApplication IDへ変更推奨（例: com.genbaos.genba_os_lite）。
        // 変更時は namespace と android/app/src/main/kotlin 配下の MainActivity.kt の
        // package/ディレクトリも合わせる必要があるため、Phase 1.0 では既定IDを保持する。
        applicationId = "com.example.genba_os_lite"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // dev / prod の Flavor 構成。
    // dev は applicationId に .dev を付け、prod と1台に同居インストール可能。
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue(type = "string", name = "app_name", value = "現場OS Lite Dev")
        }
        create("prod") {
            dimension = "env"
            resValue(type = "string", name = "app_name", value = "現場OS Lite")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
