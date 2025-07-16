// This block reads the flutter SDK path from local.properties
def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

// This block loads the keystore properties from key.properties
// Ensure key.properties is in your 'android' directory and is added to .gitignore
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
} else {
    // Optional: Log a warning if key.properties is not found, especially for debug builds
    // println("Warning: key.properties not found. Release builds might fail without it.")
}

// These properties are typically defined by Flutter for versioning
def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // Import the Firebase BoM to manage Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))

    // Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth") // Required for Firebase Authentication

    // Dependency for Google Sign-In services
    implementation("com.google.android.gms:play-services-auth:21.0.0") // Use the latest stable version

    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}

android {
    namespace = "com.coolbeanstech.quizzical"
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
        applicationId = "com.coolbeanstech.quizzical"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Define signing configurations for debug and release builds
    signingConfigs {
        // Debug signing configuration (usually handled by Android Studio default)
        debug {
            // Android Studio usually provides a default debug keystore.
            // You can explicitly define it here if needed, but often not necessary.
            // storeFile file("debug.keystore")
            // storePassword "android"
            // keyAlias "androiddebugkey"
            // keyPassword "android"
        }
        // Release signing configuration, reading from key.properties
        release {
            if (keystorePropertiesFile.exists()) {
                storeFile file(keystoreProperties.getProperty('storeFile'))
                storePassword keystoreProperties.getProperty('storePassword')
                keyAlias keystoreProperties.getProperty('keyAlias')
                keyPassword keystoreProperties.getProperty('keyPassword')
            } else {
                // Handle case where key.properties is missing for release build
                // This will cause the build to fail if not properly handled
                throw new GradleException("key.properties not found for release signing. Please create it in the 'android' directory.")
            }
        }
    }

    buildTypes {
        release {
            // Apply the release signing config
            signingConfig signingConfigs.release
                    minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
        debug {
            // For debug builds, you can keep the default debug signing or explicitly set it
            signingConfig signingConfigs.debug // Explicitly use debug signing config
        }
    }
}

flutter {
    source = "../.."
}
