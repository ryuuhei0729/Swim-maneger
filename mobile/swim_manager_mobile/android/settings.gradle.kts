pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        
        // local.propertiesファイルが存在する場合は読み込み
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        
        // local.propertiesからflutter.sdkを取得、なければ環境変数から取得
        val flutterSdkPath = properties.getProperty("flutter.sdk") ?: System.getenv("FLUTTER_SDK")
        
        // SDKパスが設定されていない場合は明確なエラーを表示
        require(!flutterSdkPath.isNullOrBlank()) { 
            "Flutter SDK path not found. Please set it in either:\n" +
            "1. local.properties file: flutter.sdk=<path_to_flutter_sdk>\n" +
            "2. FLUTTER_SDK environment variable\n" +
            "Current working directory: ${System.getProperty("user.dir")}"
        }
        
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}

include(":app")
