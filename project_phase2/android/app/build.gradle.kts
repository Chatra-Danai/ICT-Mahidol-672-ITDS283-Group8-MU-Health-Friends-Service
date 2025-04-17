plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project_phase2"
    compileSdk = 34 // Use explicit version instead of flutter.compileSdkVersion
    
    // Explicit NDK version
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.project_phase2"
        minSdk = 21 // Explicit version
        targetSdk = 34 // Explicit version
        versionCode = 1 // Explicit version
        versionName = "1.0" // Explicit version
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Workaround for plugin compatibility
configurations.all {
    resolutionStrategy {
        force("androidx.core:core-ktx:1.12.0")
        force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.10")
    }
}