plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    // It applies Kotlin itself while android.builtInKotlin is false (gradle.properties).
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.jon.echonotes"
    // permission_handler 13 compiles against Android 17 (API 37), one above
    // Flutter's default, and an app must compile against at least what its
    // plugins do.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The app's id on Google Play. It can never change once the app is
        // published (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jon.echonotes"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

dependencies {
    // NotificationCompat and ServiceCompat, for RecordingService. The same
    // version the plugins already bring in.
    implementation("androidx.core:core-ktx:1.13.1")
}
