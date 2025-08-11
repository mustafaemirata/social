plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services' // FlutterFire eklentisi
}

android {
    namespace 'com.example.social'
    compileSdk 33

    defaultConfig {
        applicationId "com.example.social"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // Burada debug signingConfig kullanılmaz genelde, eğer imzalı apk yapacaksan buraya imza dosyası konmalı
            // signingConfig signingConfigs.debug  // bu satırı kaldırabilir veya kendi imzalama yapılandırmanı ekleyebilirsin
            minifyEnabled false
            shrinkResources false
            // proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.2.0')
    implementation 'com.google.firebase:firebase-auth-ktx'
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.20"
}
