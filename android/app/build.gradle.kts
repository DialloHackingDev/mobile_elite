plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.naissance"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.naissance"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-the-gradle-build-configuration.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode()
        versionName = flutter.versionName()
    }

    buildTypes {
        debug {
            // Disable stripping debug symbols to avoid issues with native libraries
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        // Disable JNI libs stripping for debug builds
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}
