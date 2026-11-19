# Hear Clock

A customizable talking clock for Android 8.0 and later. Tap anywhere on the clock to hear the local time through Android’s text-to-speech voice. With TalkBack, focus the clock and double-tap.

## Make the clock yours

1. Open **Settings**. Choose digit and background colors independently from the named swatches or enter a six-digit RGB hex color.
2. Adjust digit size, typeface, weight, and the 12-hour or 24-hour format. **Device** follows the phone’s time format.
3. Tap **Save settings** to update the app and every placed widget. To recover the original high-contrast face, choose **Restore defaults**, then **Save settings**.

## Add it to the home screen

Tap **Add widget** and confirm placement in your launcher. You can also touch and hold an empty spot on the home screen, open **Widgets**, and drag **Hear Clock** into place. Touch and hold the clock, then drag its resize handles. Tapping the widget reads the time while the home screen stays open.

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

The APK is written to `build/app/outputs/flutter-apk/app-release.apk` and uses the local Android debug signing key. The Flutter interface and native Android widget share a preferences store through a platform channel. Android’s `TextClock` keeps the widget current while the app is closed.
