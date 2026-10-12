import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.zapclock.zap_clock"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "jp.godzhigella.zapclock"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // key.properties ファイルまたは環境変数から署名情報を取得
            val keystorePropertiesFile = file("${rootProject.projectDir}/key.properties")
            println("🔍 Looking for key.properties at: ${keystorePropertiesFile.absolutePath}")
            println("🔍 File exists: ${keystorePropertiesFile.exists()}")
            
            if (keystorePropertiesFile.exists()) {
                // key.properties ファイルから読み込み（ローカル開発用）
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                
                // storeFile のパスを rootProject からの相対パスとして解釈
                val storeFilePath = keystoreProperties["storeFile"] as String
                storeFile = file("${rootProject.projectDir}/${storeFilePath}")
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                
                println("✅ Release signing configured from key.properties")
                println("✅ Keystore file: ${storeFile!!.absolutePath}")
            } else {
                // 環境変数から取得（CI環境用）
                val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
                val keyAlias = System.getenv("KEY_ALIAS")
                val keyPassword = System.getenv("KEY_PASSWORD")
                val keystoreFile = System.getenv("KEYSTORE_FILE")?.let { file(it) }
                    ?: rootProject.file("upload-keystore.jks")
                
                if (keystorePassword != null && keyAlias != null && keyPassword != null && keystoreFile.exists()) {
                    // 環境変数から設定（CI環境）
                    storeFile = keystoreFile
                    storePassword = keystorePassword
                    this.keyAlias = keyAlias
                    this.keyPassword = keyPassword
                    println("✅ Release signing configured from environment variables")
                } else {
                    // エラー: 署名設定がない
                    throw GradleException("""
                        ❌ Release signing configuration not found!
                        
                        Option 1 (Recommended for local development):
                        Create 'android/key.properties' file with:
                            storePassword=your_keystore_password
                            keyPassword=your_key_password
                            keyAlias=upload
                            storeFile=../upload-keystore.jks
                        
                        Option 2 (For CI environment):
                        Set environment variables:
                            export KEYSTORE_PASSWORD="your_keystore_password"
                            export KEY_ALIAS="upload"
                            export KEY_PASSWORD="your_key_password"
                            export KEYSTORE_FILE="path/to/keystore"
                    """.trimIndent())
                }
            }
        }
    }

    buildTypes {
        release {
            // リリースビルドは release 署名設定を使用
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
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
    // ZapClockApplication observes the alarm plugin's AlarmRingingLiveData
    // directly, so LiveData must be on this module's compile classpath. The
    // Flutter embedding only brings lifecycle-common/runtime (2.7.0).
    implementation("androidx.lifecycle:lifecycle-livedata-core:2.7.0")
}
