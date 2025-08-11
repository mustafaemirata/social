buildscript {
    ext.kotlin_version = '1.8.20'  // Kotlin sürümü değişken olarak tanımlandı

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.1' // güncel Gradle plugin versiyonu
        classpath 'com.google.gms:google-services:4.3.15' // Google Services plugin
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version" // Kotlin plugin versiyonu değişkenden çekiliyor
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
