import java.util.Properties
import java.io.FileInputStream
import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Apply Google Services Plugin for Firebase
    id("com.google.gms.google-services")
    // Apply Firebase Crashlytics Plugin
    id("com.google.firebase.crashlytics")
}

// Load signing configuration if available
val signingPropsFile = rootProject.file("app/signing.properties")
val signingProps = Properties()
if (signingPropsFile.exists()) {
    signingProps.load(FileInputStream(signingPropsFile))
}

android {
    namespace = "com.example.ottr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ottr"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21 // Set minimum SDK to 21 as per requirements
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Setting multiDex enabled for large app with many dependencies
        multiDexEnabled = true
    }

    // Define signing config if properties are available
    if (signingProps.isNotEmpty()) {
        signingConfigs {
            create("release") {
                storeFile = file(signingProps.getProperty("storeFile"))
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if available, otherwise debug
            if (signingProps.isNotEmpty()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            
            // Enable R8 shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        debug {
            // Apply crashlytics in debug mode too for testing
            extensions.configure<CrashlyticsExtension>("firebaseCrashlytics") {
                mappingFileUploadEnabled = false
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Multidex support for older Android versions
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Firebase dependencies
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))
    // Firebase Analytics for tracking usage
    implementation("com.google.firebase:firebase-analytics-ktx")
    // Firebase Auth for Google Sign-In
    implementation("com.google.firebase:firebase-auth-ktx")
    // Firebase Firestore for database
    implementation("com.google.firebase:firebase-firestore-ktx")
    // Firebase Cloud Messaging for push notifications
    implementation("com.google.firebase:firebase-messaging-ktx")
    // Firebase Crashlytics for error reporting
    implementation("com.google.firebase:firebase-crashlytics-ktx")
}
