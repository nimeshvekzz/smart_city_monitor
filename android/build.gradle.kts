allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Overrides removed for compatibility with Gradle 8.x and Flutter 3.22+

subprojects {
    project.evaluationDependsOn(":app")
}

// Dependencies are now managed in settings.gradle.kts for modern Flutter projects.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}