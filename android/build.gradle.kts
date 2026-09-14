extra.apply {
    set("compileSdkVersion", 34)
    set("targetSdkVersion", 34)
    set("minSdkVersion", 21)
    set("defaultMinSdkVersion", 21)
    set("defaultTargetSdkVersion", 34)
    set("defaultCompileSdkVersion", 34)
    set("sourceCompatibility1", JavaVersion.VERSION_17)
    set("targetCompatibility1", JavaVersion.VERSION_17)
    set("viewBindingEnabled", false)
    set("buildToolsVersion", "34.0.0")
    set("ndkVersion", "25.1.8937393")
}
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
