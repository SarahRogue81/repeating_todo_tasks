# Task Management

- [ ] Upgrade Kotlin and AGP versions
	- [/] Research latest stable versions
	- [ ] Update `pubspec.yaml`
	- [ ] Update `android/gradle.properties`
	- [ ] Update `android/settings.gradle.kts`
	- [ ] Update `android/app/build.gradle.kts`
- [ ] Migrate to Built-in Kotlin (Remove KGP)
	- [ ] Verify manual KGP removal (if any)
	- [ ] Verify `android.builtInKotlin=true`
- [ ] Verification
	- [ ] Run `./gradlew clean`
	- [ ] Run `flutter build apk --debug`
