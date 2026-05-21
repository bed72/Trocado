import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("version.properties")

if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterMinSdk: Int? = localProperties.getProperty("trocado.minSdk")?.toInt()
val flutterAndroidSkd: Int? = localProperties.getProperty("trocado.androidSdkVersion")?.toInt()
var flutterNdkVersion: String = localProperties.getProperty("trocado.ndkVersion") ?: "29.0.14206865"

android {
    ndkVersion = flutterNdkVersion
    compileSdk = flutterAndroidSkd
    namespace = "br.com.bed.trocado"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        minSdk = flutterMinSdk
        targetSdk = flutterAndroidSkd
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        applicationId = "br.com.bed.trocado"
    }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("TROCADO_KEY_ALIAS")
            keyPassword = System.getenv("TROCADO_KEY_PASSWORD")
            storePassword = System.getenv("TROCADO_STORE_PASSWORD")
            storeFile = file(System.getenv("TROCADO_KEYSTORE_PATH") ?: "../../.keys/trocado.jks")
        }
    }

    buildTypes {
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }

        getByName("profile") {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }

        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_21)
    }
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.2.0")
    implementation("com.google.mlkit:barcode-scanning:17.3.0")
}

flutter {
    source = "../.."
}
