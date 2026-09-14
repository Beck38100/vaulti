import java.util.Properties
import java.io.FileInputStream

// Secrets de signature, tenus hors du dépôt (voir android/key.properties).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) load(FileInputStream(file))
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "fr.vaulti.app"
    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "fr.vaulti.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Deux variantes, pour installer une version de test à côté de la vraie
    // application sans jamais l'écraser : `flutter run --flavor production`
    // (identifiant et nom inchangés) ou `--flavor dev` (fr.vaulti.app.dev,
    // « Vaulti Dev »). Une fois des variantes définies, Gradle exige toujours
    // d'en choisir une — il n'y a plus de commande sans --flavor.
    flavorDimensions += "environment"
    productFlavors {
        create("production") {
            dimension = "environment"
        }
        create("dev") {
            dimension = "environment"
            applicationId = "fr.vaulti.app.dev"
        }
    }

    signingConfigs {
        create("release") {
            // Sans key.properties (poste sans la clé), on n'échoue pas ici :
            // c'est la compilation en mode release qui le signalera.
            keystoreProperties.getProperty("storeFile")?.let {
                storeFile = file(it)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
