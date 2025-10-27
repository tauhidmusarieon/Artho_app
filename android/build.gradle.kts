buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("com.google.gms:google-services:4.3.15") // correct version
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
