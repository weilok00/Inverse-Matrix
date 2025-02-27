allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define a custom build directory
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Ensure subprojects depend on the app project
    project.evaluationDependsOn(":app")
}

// Register a clean task to remove the build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
