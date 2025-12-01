plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.artho_app"

    // Flutter থেকে আসা ভার্সনগুলো ব্যবহার করা হচ্ছে
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.artho_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        // Debug build: shrink/obfuscation বন্ধ
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        // Release build: shrink/obfuscation চালু (প্রোডাকশনের জন্য সুপারিশকৃত)
        getByName("release") {
            // TODO: আপনার রিলিজ সাইনিং এখানে দিন
            // signingConfig = signingConfigs.getByName("release")
            // ডেভেলপমেন্টে টেস্ট করতে চাইলে debug সাইনিং ব্যবহার করতে পারেন:
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase Bill of Materials (BoM)
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))

    // ✅ Firebase services you use
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // ✅ Common Android libs
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
}
