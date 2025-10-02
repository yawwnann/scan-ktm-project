plugins {plugins {

    id("com.android.application")    id("com.android.application")

    // START: FlutterFire Configuration    // START: FlutterFire Configuration

    id("com.google.gms.google-services")    id("com.google.gms.google-services")

    // END: FlutterFire Configuration    // END: FlutterFire Configuration

    id("org.jetbrains.kotlin.android")    id("kotlin-android")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.

    id("dev.flutter.flutter-gradle-plugin")    id("dev.flutter.flutter-gradle-plugin")

}}



android {android {

    namespace = "com.example.stnk_check_uad"    namespace = "com.example.stnk_check_uad"

    compileSdk = 34    compileSdk = 34

    ndkVersion = flutter.ndkVersion

    defaultConfig {

        applicationId = "com.example.stnk_check_uad"    compileOptions {

        minSdk = 21        sourceCompatibility = JavaVersion.VERSION_11

        targetSdk = 34        targetCompatibility = JavaVersion.VERSION_11

        versionCode = flutter.versionCode        // Suppress warning about obsolete options

        versionName = flutter.versionName        tasks.withType<JavaCompile>().configureEach {

        multiDexEnabled = true            options.compilerArgs.addAll(listOf("-Xlint:-options", "-Xlint:-deprecation"))

        vectorDrawables { useSupportLibrary = true }        }

    }    }



    buildTypes {    kotlinOptions {

        release {        jvmTarget = JavaVersion.VERSION_11.toString()

            // Signing with the debug keys for now, so `flutter run --release` works.    }

            signingConfig = signingConfigs.getByName("debug")

            // Keep minify off for now to avoid resource/proguard issues while we get a clean build    defaultConfig {

            isMinifyEnabled = false        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).

            isShrinkResources = false        applicationId = "com.example.stnk_check_uad"

            // If you later enable minify, also include proguard rules:        // You can update the following values to match your application needs.

            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")        // For more information, see: https://flutter.dev/to/review-gradle-config.

        }        minSdkVersion flutter.minSdkVersion

    }        targetSdk = 34

        versionCode = flutter.versionCode

    compileOptions {        versionName = flutter.versionName

        sourceCompatibility = JavaVersion.VERSION_11        

        targetCompatibility = JavaVersion.VERSION_11        // Enable multidex if needed

    }        multiDexEnabled = true

    }

    kotlinOptions {

        jvmTarget = "11"    buildTypes {

    }        release {

            // TODO: Add your own signing config for the release build.

    packaging {            // Signing with the debug keys for now, so `flutter run --release` works.

        resources {            signingConfig = signingConfigs.getByName("debug")

            excludes += setOf("META-INF/LICENSE*", "META-INF/NOTICE*")            

        }            // Disable minify temporarily to avoid resource linking issues

    }            isMinifyEnabled = false

}            isShrinkResources = false

        }

flutter {    }

    source = "../.."}

}

flutter {
    source = "../.."
}
