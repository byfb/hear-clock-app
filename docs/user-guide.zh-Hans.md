# Hear Clock 使用指南

## 把时钟放到桌面上

1. 在运行 Android 8.0 或更高版本的手机上，登录有权访问这个私有仓库的 GitHub 账号。打开最新版本页面，在 **Assets** 下下载 APK，打开文件即可安装。[下载最新 Android 版](https://github.com/byfb/hear-clock/releases/latest)
2. 打开 Hear Clock，点 **Add widget**（添加小组件）并确认。也可以长按桌面空白处，打开小组件列表，把 **Hear Clock** 拖到想放的位置。
3. 要调整大小，长按时钟，松开手指，再拖动边框上的圆点。[Android 小组件使用说明](https://support.google.com/android/answer/9450271?hl=zh-Hans)

点一下时钟的任意位置，手机就会在桌面上读出时间。使用 TalkBack 时，可以滑动手指切换焦点，也可以直接触摸屏幕找到时钟，然后在屏幕上轻点两下。[TalkBack 手势](https://support.google.com/accessibility/android/answer/6151827?hl=zh-Hans)

如果更新后原来的时钟变成空白，打开一次 Hear Clock，再回到桌面。[v0.3.2 修复说明（英文）](releases/v0.3.2.md)

## 选择钟面

打开 **Settings**（设置），点 **Appearance**（外观）。每款钟面都会记住自己的设置。菜单的深浅配色跟随手机设置。

- **Digital**（数字）把小时和分钟放在同一行。可以加上秒数，也可以更改数字和背景的颜色。
- **Stacked**（上下排列）把小时放在上面，分钟放在下面，两行数字和背景都能分别选色。
- **Analog**（指针）可显示全部 12 个数字、只标出 3、6、9、12 点，或只显示刻度。你可以更改背景和刻度颜色，单独调整每根指针的颜色、长度和粗细。打开 **Show second hand**（显示秒针）即可调整秒针。

这两款数字钟面都能调字号、换字体或使用粗体。使用 12 小时制时，也可以把 8:05 显示为 08:05。

在 **Color combinations**（配色）中可以选择黑底白字、白底黑字、黑底黄字，或恢复当前钟面的原有配色。要单独改色，可以按颜色名称选择，也可以输入十六进制色值。如果对比度低于 4.5:1，预览会指出哪组数字、刻度或哪根指针与背景的对比度最低。[数字钟面示例](previews/digital-light.png) · [指针钟面示例](previews/analog-dark.png)

**Time format**（时间格式）同时影响显示和报时。选择 **Device**（跟随设备），即可沿用手机的 12 或 24 小时制。在 Android 8 至 11 上，桌面指针时钟开启秒针期间，系统会一直显示一条通知。

## 设置报时语言和语速

在 **Settings** 中点 **Voice**（语音），选择手机文字转语音引擎已安装的语言。**Speech speed**（语速）可设为 50% 到 200%，点 **Test voice**（试听）即可听到效果。找不到需要的语言时，可以在 Android 的文字转语音设置中安装语音数据。[Android 语音设置说明](https://support.google.com/accessibility/android/answer/6006983?hl=zh-Hans)

点 **Save settings**（保存设置），应用里的时钟和桌面上的所有 Hear Clock 小组件都会用上这套外观和语音。要恢复默认设置，在 **Appearance** 中点 **Restore all defaults**，再点 **Save settings**。钟面和语音都会恢复默认值。

[返回 Hear Clock 首页](../README.zh-Hans.md)
