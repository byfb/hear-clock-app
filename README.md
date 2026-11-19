# Hear Clock

A customizable talking clock for Android 8.0 and later. Tap anywhere on the clock to hear the local time through Android’s text-to-speech voice. With TalkBack, focus the clock and double-tap.

## Make the clock yours

Open **Settings** and choose a clock face. Each face remembers its own appearance.

| Face | What you can change |
| --- | --- |
| Digital | Digit and background colors, size, typeface, bold digits, a leading zero in 12-hour time, and seconds |
| Stacked | Separate colors for the hours and minutes on two lines, background color, digit size, typeface, bold digits, and a leading zero in 12-hour time |
| Analog | Dial background, marking color, numbers or ticks, and the color, length, and thickness of each hand. Turn on **Show second hand** to edit it. |

Choose a named color or enter a six-digit RGB hex value. **Time format** applies across the faces and to speech. **Device** follows the phone’s 12-hour or 24-hour preference.

Under **Speech language**, choose a language offered by your Android text-to-speech engine. Set **Speech speed** between 50% and 200% and tap **Test voice** to hear the change. **Save settings** applies your choices to the app and every placed widget. **Restore defaults** followed by **Save settings** restores the original appearance and voice settings.

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

The APK is written to `build/app/outputs/flutter-apk/app-release.apk` and uses the local Android debug signing key.

## Create a versioned release

From the repository root, run `dart run tool/release.dart minor` for a new feature, `patch` for a fix, or `major` for a breaking change. Add `--dry-run` to preview the next version. Ordinary builds reuse the current version.

The release command builds the APK, increments the Android build number, records the completed version in `pubspec.yaml`, and saves the APK as `build/releases/hear-clock-<version>+<build>.apk`. Commit the version change and tag the release `v<version>`.
