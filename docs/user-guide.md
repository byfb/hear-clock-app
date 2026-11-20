# Using Hear Clock

## Put the clock on your home screen

1. On a phone running Android 8.0 or later, sign in to GitHub with an account that can read this private repository. Under **Assets** on the latest release, download the APK and open it to install Hear Clock. [Latest Android release](https://github.com/byfb/hear-clock-app/releases/latest)
2. Open Hear Clock, tap **Add widget**, and confirm. If your launcher uses a widget picker, touch and hold an empty spot on the home screen, open **Widgets**, and drag **Hear Clock** into place.
3. To resize the clock, touch and hold it, lift your finger, then drag the handles around its edge. [Android’s guide to adding and resizing widgets](https://support.google.com/android/answer/9450271)

Tap anywhere on the clock to hear the time. The home screen stays open. With TalkBack, swipe to the clock or find it by touch, then double-tap anywhere on the screen. [TalkBack gestures](https://support.google.com/accessibility/android/answer/6151827)

If a widget you already placed is blank after an update, open Hear Clock once and return to the home screen. [Widget fix in v0.3.2](releases/v0.3.2.md)

## Change the app language

Under **Settings → Appearance → App language**, choose English, 简体中文, 繁體中文, or **Follow device language**. The menus and TalkBack labels change immediately. On Android 13 or later you can also use Android’s app language settings. The home-screen clock uses your phone’s regional time format.

To change the language you hear, use **Settings → Voice → Speech language**. **Device language** uses the phone’s language even when the menus are in another language.

## Choose a clock face

Open **Settings**, then **Appearance**. Each face remembers its own settings. The menus follow your phone’s light or dark theme.

- **Digital** shows the hours and minutes on one line. You can add seconds and choose colors for the digits and background.
- **Stacked** puts the hours above the minutes. Pick a color for each line and one for the background.
- **Analog** can show all twelve numbers, just the quarter hours, or tick marks. Choose the background and marking colors, then adjust each hand’s color, length, and thickness. Turn on **Show second hand** to edit it.

On either digital face, you can change the digit size and typeface or turn on bold text. In 12-hour time, you can choose to show 8:05 as 08:05.

Under **Color combinations**, choose white on black, black on white, yellow on black, or the face’s original colors. To change one color, pick it by name or enter a hex value. When contrast drops below 4.5:1, the preview names the digits, markings, or hand with the lowest contrast against the background. [Digital example](previews/digital-light.png) · [Analog example](previews/analog-dark.png)

**Time format** controls both the display and the spoken time. Choose **Device** to follow the phone’s 12-hour or 24-hour setting. On Android 8 through 11, turning on the second hand for an analog home-screen widget keeps a notification visible while the hand is on.

## Choose what the clock says

Open **Settings → Voice**. **Speak on tap** is on by default. Turn it off for a silent clock. If you use Android TalkBack, it can still read the time when you focus the clock.

Turn on **Include today’s date** to hear the time followed by the weekday and full date. The date is off by default and uses the language you choose under **Speech language**.

Choose an installed voice language and set **Speech speed** between 50% and 200%. Tap **Test voice** to hear your choices before saving. If your language is missing, you can install voice data in Android’s text-to-speech settings. [Android speech settings](https://support.google.com/accessibility/android/answer/6006983)

Tap **Save settings** to apply both tabs to the app and every widget you’ve placed. To start over, tap **Restore all defaults** in **Appearance**, then **Save settings**. This resets the voice as well as the face.

[Back to Hear Clock](../README.md)
