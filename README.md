# Hear Clock

A customizable talking clock for Android 8.0 and later. Tap anywhere on the clock to hear the local time through Android’s text-to-speech voice. With TalkBack, focus the clock and double-tap.

## Make the clock yours

Open **Settings → Appearance** and choose a clock face. Each face remembers its own appearance. The app’s menus follow Android’s light or dark theme.

| Face | What you can change |
| --- | --- |
| Digital | Digit and background colors, size, typeface, bold digits, a leading zero in 12-hour time, and seconds |
| Stacked | Separate colors for the hours and minutes on two lines, background color, digit size, typeface, bold digits, and a leading zero in 12-hour time |
| Analog | Dial background, marking color, numbers or ticks, and the color, length, and thickness of each hand. Turn on **Show second hand** to edit it. |

Open **Color combinations** for white on black, black on white, yellow on black, or the face’s original colors. A combination changes only that face’s colors. You can also change individual colors by name or hex value. The preview identifies the lowest-contrast digits, markings, or hand when the contrast ratio falls below 4.5:1. **Time format** applies across the faces and to speech. **Device** follows the phone’s 12-hour or 24-hour preference.

In **Settings → Voice**, choose a language offered by your Android text-to-speech engine. Set **Speech speed** between 50% and 200% and tap **Test voice** to hear the change. **Save settings** applies the choices from both tabs to the app and every placed widget. **Restore all defaults** in Appearance followed by **Save settings** restores the original appearance and voice settings.

See the [black-on-white digital clock](docs/previews/digital-light.png) and the [yellow-on-black analog clock](docs/previews/analog-dark.png).

The design draws on studies with blind and low-vision phone users. [Read the accessibility research and participant testing questions](docs/accessibility-research.md).

## Add it to the home screen

Tap **Add widget** and confirm placement in your launcher. You can also touch and hold an empty spot on the home screen, open **Widgets**, and drag **Hear Clock** into place. Touch and hold the clock, then drag its resize handles. Tapping the widget reads the time while the home screen stays open.

On Android 8–11, enabling the second hand on a placed analog widget displays an ongoing notification while the second hand is enabled.

## Development

Built with Flutter 3.47.7, Dart 3.13.5, JDK 17, and Android SDK 36. Connect an Android device or start an emulator, then run the app.

```sh
flutter pub get
flutter run
```

Run the checks and build a local test APK.

```sh
flutter analyze
flutter test
flutter build apk --release
```

The local test APK is written to `build/app/outputs/flutter-apk/app-release.apk` and uses the Android debug signing key by default. To sign a local build with the release key, set `HEAR_CLOCK_KEYSTORE` to the absolute path of the PKCS12 keystore and `HEAR_CLOCK_KEYSTORE_PASSWORD` to its password. The key alias is `hear-clock`. The public certificate fingerprint is in [android/release-cert.sha256](android/release-cert.sha256).

## Create a versioned release

Prepare the version on the `release` branch. Use `patch` for fixes or packaging changes, `minor` for new features, and `major` for breaking changes. Each release also increments the Android build number.

```sh
git switch release
git pull --ff-only origin release
git fetch origin main
git merge --no-ff origin/main -m "chore(release): promote main"
dart run tool/release.dart patch --prepare
```

Write the dated, user-facing notes in `docs/releases/vX.Y.Z.md`, including any upgrade steps and a changelog link. Commit the notes and `pubspec.yaml` together. Replace `X.Y.Z` below with the prepared version.

```sh
git add pubspec.yaml docs/releases/vX.Y.Z.md
git commit -m "chore(release): prepare version X.Y.Z"
git tag -a vX.Y.Z -m "Hear Clock X.Y.Z"
git push origin release
git push origin vX.Y.Z
```

A new version tag starts a check that its commit is in the first-parent history of `release` and its version matches `pubspec.yaml`. The eligible tag runs analysis and tests, builds a universal APK, verifies its version and signing certificate, and publishes it with the notes to [GitHub Releases](https://github.com/byfb/hear-clock/releases). Branch pushes do not run the workflow. Merge the released version back into `main` for the next development cycle.

The repository Actions secrets `ANDROID_SIGNING_KEYSTORE` and `ANDROID_SIGNING_PASSWORD` hold the base64-encoded PKCS12 keystore and its password. Downloads from this private repository require a GitHub account with read access.

For local release testing, omit `--prepare` to build an APK in `build/releases/` before recording the version. Add `--dry-run` to preview a version change.

## License

Copyright 2026 byfb. Hear Clock is licensed under the GNU General Public License, version 3 only (`GPL-3.0-only`). [Read the license](LICENSE).
