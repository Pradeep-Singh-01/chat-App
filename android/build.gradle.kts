buildscript {
    val kotlinVersion by extra("2.1.0")
    repositories {
        google()
        mavenCentral()
    }
//    ext {
//        ext.kotlin_version = '2.1.0'
//    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.10.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        // The Google Services plugin is applied via the plugins {} block below,
        // but its classpath dependency is declared here if needed by other logic
        // (often it's self-contained by the plugins block).
        // For clarity, it's good to know where it comes from:
        classpath("com.google.gms:google-services:4.4.2")
    }
}


//plugins {
//    // ...
//
//    // Add the dependency for the Google services Gradle plugin
//    id("com.google.gms.google-services") version "4.4.2" apply false
//
//}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

//val newRootBuildDir: java.io.File = rootProject.file("../build/${rootProject.name}") // More robust path
//layout.buildDirectory.set(newRootBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}
//subprojects {
//    project.evaluationDependsOn(":app")
//}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
