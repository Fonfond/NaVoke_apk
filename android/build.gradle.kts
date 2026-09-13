// android/build.gradle
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ✅ ЕДИНСТВЕННОЕ, ЧТО НУЖНО ДОБАВИТЬ — ЭТОТ БЛОК
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Плагин Google Services для Firebase
        classpath("com.google.gms:google-services:4.3.15")
    }
}