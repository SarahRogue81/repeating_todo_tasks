# Upgrade Kotlin and Migrate to Built-in Kotlin

The goal is to upgrade the Kotlin version to the latest stable (2.3.21) and migrate the project to use "Built-in Kotlin" by removing the manual Kotlin Gradle Plugin (KGP) application and using the latest stable Android Gradle Plugin (AGP) (8.13.2).

## User Review Required

> [!IMPORTANT]
> - I am upgrading Kotlin to **2.3.21** and AGP to **8.13.2**. These are the latest stable versions as of May 2026 for Flutter 3.44.
> - I am also upgrading the `shared_preferences` package to **^2.5.5** to resolve the KGP warning associated with it.

## Proposed Changes

### Flutter Configuration

#### [pubspec.yaml](file:///home/emogirl/.gemini/antigravity/scratch/repeating_todo_tasks/pubspec.yaml)

- Upgrade `shared_preferences` to `^2.5.5`.

---

### Android Build Configuration

#### [gradle.properties](file:///home/emogirl/.gemini/antigravity/scratch/repeating_todo_tasks/android/gradle.properties)

- Set `android.builtInKotlin=true`.
- Set `android.newDsl=true`.

#### [settings.gradle.kts](file:///home/emogirl/.gemini/antigravity/scratch/repeating_todo_tasks/android/settings.gradle.kts)

- Upgrade `com.android.application` version to `8.13.2`.
- Ensure NO `org.jetbrains.kotlin.android` plugin is defined here.

#### [app/build.gradle.kts](file:///home/emogirl/.gemini/antigravity/scratch/repeating_todo_tasks/android/app/build.gradle.kts)

- Remove `id("org.jetbrains.kotlin.android")` from the `plugins` block.
- Keep the `kotlin` block for `compilerOptions` as it is supported by the built-in Kotlin feature of AGP.

---

## Verification Plan

### Automated Tests
- Run `./gradlew clean` in the `android` directory to ensure the build configuration is valid.
```bash
cd android && ./gradlew clean
```
- Run `flutter build apk --debug` to verify the app builds with the new configuration.
```bash
/home/emogirl/develop/flutter/bin/flutter build apk --debug
```

### Manual Verification
- Check the output of the build for any KGP-related warnings.
