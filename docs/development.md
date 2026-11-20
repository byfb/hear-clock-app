# Build and release Hear Clock

## Run the app

The release toolchain uses Flutter 3.47.7, Dart 3.13.5, JDK 17, and Android SDK 36. Connect an Android device or start an emulator, then run these commands from the repository root.

```sh
flutter pub get
flutter run
```

## Test and build an APK

```sh
flutter analyze
flutter test
flutter build apk --release
```

To test widget resizing and the full-face tap target, connect an Android 15 test emulator. After the Flutter build, run the native test from the repository root.

```sh
(cd android && ./gradlew :app:connectedDebugAndroidTest)
```

The local APK is written to `build/app/outputs/flutter-apk/app-release.apk` and uses the Android debug signing key by default. For a release-signed local build, set `HEAR_CLOCK_KEYSTORE` to the absolute path of the PKCS12 keystore and `HEAR_CLOCK_KEYSTORE_PASSWORD` to its password. The key alias is `hear-clock`. [Release certificate fingerprint](../android/release-cert.sha256)

## Update translations

Edit the message catalogs in [lib/l10n](../lib/l10n/). `app_en.arb` defines the message keys and placeholders, `app_zh.arb` supplies Simplified Chinese, and `app_zh_Hant.arb` supplies Traditional Chinese. Run `flutter gen-l10n` before analyzing and testing changes. Android widget descriptions, notifications, and speech errors use the matching string resources in [res](../android/app/src/main/res/).

## Publish a release

Prepare the version on the `release` branch. Use `patch` for fixes or packaging changes, `minor` for new features, and `major` for breaking changes. Each release increments the Android build number. [Versioning tool](../tool/release.dart)

```sh
git switch release
git pull --ff-only origin release
git fetch origin main
git merge --no-ff origin/main -m "chore(release): promote main"
dart run tool/release.dart patch --prepare
```

Write the dated release notes in `docs/releases/vX.Y.Z.md`. Describe what changed for users, include any upgrade steps, and link the changelog. Replace `X.Y.Z` below with the prepared version. [Previous release notes](releases/)

```sh
git add pubspec.yaml docs/releases/vX.Y.Z.md
git commit -m "chore(release): prepare version X.Y.Z"
git push origin release
git tag -a vX.Y.Z -m "Hear Clock X.Y.Z"
git push origin vX.Y.Z
```

A new version tag starts the release workflow. It checks that the tagged commit is in the first-parent history of `release` and that the version matches `pubspec.yaml`. GitHub Actions then analyzes and tests the app, builds a universal APK, verifies its signature, version and license, and publishes it with the release notes. After it publishes, merge `release` back into `main`. [Release workflow](../.github/workflows/release.yml) · [GitHub Releases](https://github.com/byfb/hear-clock-app/releases)

The workflow reads the base64-encoded PKCS12 keystore from the `ANDROID_SIGNING_KEYSTORE` Actions secret and its password from `ANDROID_SIGNING_PASSWORD`. For a local release test, omit `--prepare` to build an APK in `build/releases/` before recording the version. Add `--dry-run` to preview a version change.

Copyright 2026 byfb. Hear Clock is licensed under version 3 of the GNU General Public License only. [License](../LICENSE)
