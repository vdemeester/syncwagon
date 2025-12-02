plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

// Gomobile build configuration
val gomobileBuildDir = file("${project.rootDir}/core/build")
val gomobileAar = file("$gomobileBuildDir/core.aar")

tasks.register<Exec>("buildGomobile") {
    group = "build"
    description = "Build Go core module using gomobile"

    workingDir = file("${project.rootDir}/core")
    commandLine("sh", "-c", """
        mkdir -p build && \
        gomobile bind -v -o build/core.aar -target=android \
            -androidapi 26 \
            github.com/vdemeester/syncwagon/core
    """.trimIndent())

    inputs.files(fileTree("${project.rootDir}/core") {
        include("**/*.go")
        exclude("build/**")
    })
    outputs.file(gomobileAar)
}

tasks.named("preBuild") {
    dependsOn("buildGomobile")
}

android {
    namespace = "com.github.vdemeester.syncwagon"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.github.vdemeester.syncwagon"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.4"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Go core module (gomobile generated)
    implementation(files(gomobileAar))

    // AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")

    // Jetpack Compose
    val composeBom = platform("androidx.compose:compose-bom:2023.10.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.navigation:navigation-compose:2.7.6")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(composeBom)
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
