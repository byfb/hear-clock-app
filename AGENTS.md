# Hear Clock

Hear Clock is a Flutter app for blind and low-vision users. Its Android home-screen widget shows local time and speaks it on tap. Keep the product focused on reading the clock and customizing its appearance and voice.

## Accessibility and UI

- Make the entire clock one accessible tap target. Read the current time on demand and keep routine clock updates quiet.
- Give controls descriptive names, visible focus, and at least 48 logical pixels of touch area. Check large system text and narrow widget sizes.
- Keep settings legible with any user-selected clock colors. Use plain labels and reserve supporting text for instructions or feedback.
- Keep app and home-screen clock settings in sync, including widgets already on the launcher.

## Working conventions

- Use Flutter and Dart tooling for the app.
- Keep local development assets in `.local/`. Strip editing metadata from artwork before committing it.
- Make atomic Conventional Commits. Keep each behavior change and its relevant checks together.
- For a new release, follow [Publish a release](docs/development.md#publish-a-release) to bump the semantic version and Android build number, commit the release notes, and tag the release.
- Run `flutter analyze` and `flutter test` for app changes. Verify launcher behavior on Android when changing the widget or speech integration.
- Lead with the result in user-facing updates. State scope positively and match claims to what was verified.
