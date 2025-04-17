// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.2") // Ensure AGP is up-to-date
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Workaround for qr_code_scanner namespace issue
    project.plugins.withId("com.android.library") {
        project.extensions.configure<com.android.build.gradle.LibraryExtension> {
            namespace = "net.touchcapture.qr.flutterqr" // Add namespace for library projects
        }
    }
}

// Your existing build directory configuration remains the same
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Force NDK version for all subprojects
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.application") {
            project.extensions.configure<com.android.build.gradle.AppExtension> {
                ndkVersion = "27.0.12077973"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}