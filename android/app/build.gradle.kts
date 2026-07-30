plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.siddesh_barcode_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "com.example.siddesh_barcode_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

val flutterRootOutputsDir = File(rootProject.projectDir.parentFile, "build/app/outputs")
val flutterRootFlutterApkDir = File(flutterRootOutputsDir, "flutter-apk")
val flutterRootDebugApkDir = File(flutterRootOutputsDir, "apk/debug")
val flutterRootReleaseApkDir = File(flutterRootOutputsDir, "apk/release")

tasks.register<Copy>("syncDebugFlutterApk") {
    from(layout.buildDirectory.dir("outputs/apk/debug"))
    include("app-debug.apk", "output-metadata.json")
    into(flutterRootFlutterApkDir)
}

tasks.register<Copy>("syncDebugStandardApk") {
    from(layout.buildDirectory.dir("outputs/apk/debug"))
    include("app-debug.apk", "output-metadata.json")
    into(flutterRootDebugApkDir)
}

tasks.register<Copy>("syncReleaseFlutterApk") {
    from(layout.buildDirectory.dir("outputs/apk/release"))
    include("app-release.apk", "output-metadata.json")
    into(flutterRootFlutterApkDir)
}

tasks.register<Copy>("syncReleaseStandardApk") {
    from(layout.buildDirectory.dir("outputs/apk/release"))
    include("app-release.apk", "output-metadata.json")
    into(flutterRootReleaseApkDir)
}

tasks.matching { it.name == "assembleDebug" }.configureEach {
    finalizedBy("syncDebugFlutterApk")
    finalizedBy("syncDebugStandardApk")
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy("syncReleaseFlutterApk")
    finalizedBy("syncReleaseStandardApk")
}