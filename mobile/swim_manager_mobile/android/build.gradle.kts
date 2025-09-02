allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Flutterルートに合わせてビルドディレクトリを設定
val newBuildDir: Provider<Directory> = rootProject.layout.buildDirectory.dir("../build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    // サブプロジェクト用のビルドディレクトリを設定
    val newSubprojectBuildDir: Provider<Directory> = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
