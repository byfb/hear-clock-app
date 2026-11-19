# Hear Clock 使用指南

## 將時鐘加入主畫面

1. 在執行 Android 8.0 或以上版本的手機上，登入有權存取此私人儲存庫的 GitHub 帳戶。前往最新版本，在 **Assets** 下下載 APK，開啟檔案即可安裝。[下載最新 Android 版](https://github.com/byfb/hear-clock/releases/latest)
2. 開啟 Hear Clock，點選 **Add widget**（加入小工具）並確認。也可以長按主畫面的空白處，開啟小工具清單，再將 **Hear Clock** 拖到想放的位置。
3. 要調整大小，長按時鐘後放開手指，再拖動邊框上的圓點。[Android 的小工具操作說明](https://support.google.com/android/answer/9450271?hl=zh-Hant)

輕點時鐘的任何位置，手機就會在主畫面讀出時間。如果使用 TalkBack，可以滑動手指切換焦點，或直接觸摸螢幕找到時鐘，再於螢幕上輕點兩下。[TalkBack 手勢](https://support.google.com/accessibility/android/answer/6151827?hl=zh-Hant)

如果更新後原有的時鐘變成空白，開啟 Hear Clock 一次，再返回主畫面。[v0.3.2 修正說明（英文）](releases/v0.3.2.md)

## 選擇鐘面

開啟 **Settings**（設定），點選 **Appearance**（外觀）。每款鐘面都會記住自己的設定。選單的深淺色會跟隨手機設定。

- **Digital**（數字）把小時和分鐘排在同一行。你可以加上秒數，也可以更改數字和背景的顏色。
- **Stacked**（上下排列）把小時放在上方、分鐘放在下方，兩行數字和背景都可分別選色。
- **Analog**（指針）可顯示全部 12 個數字、只標出 3、6、9、12 點，或只顯示刻度。你可以更改背景與刻度顏色，並逐根調整指針的顏色、長度和粗幼。開啟 **Show second hand**（顯示秒針）即可調整秒針。

這兩款數字鐘面都可調整數字大小和字體，也可以用粗體。使用 12 小時制時，可選擇把 8:05 顯示為 08:05。

在 **Color combinations**（配色）可選黑底白字、白底黑字、黑底黃字，或恢復目前鐘面的原有配色。要單獨改色，可按顏色名稱選取，或輸入十六進位色碼。如果對比度低於 4.5:1，預覽會指出哪組數字、刻度或哪根指針與背景的對比度最低。[數字鐘面範例](previews/digital-light.png) · [指針鐘面範例](previews/analog-dark.png)

**Time format**（時間格式）同時影響顯示和報時。選擇 **Device**（跟隨裝置），即可沿用手機的 12 或 24 小時制。在 Android 8 至 11 上，主畫面指針時鐘啟用秒針期間，系統會持續顯示一則通知。

## 調整報時語言和語速

在 **Settings** 中點選 **Voice**（語音），選擇手機文字轉語音引擎已安裝的語言。**Speech speed**（語速）可設為 50% 至 200%，點選 **Test voice**（試聽）即可聽聽效果。找不到想要的語言時，可到 Android 的文字轉語音設定安裝語音資料。[Android 語音設定說明](https://support.google.com/accessibility/android/answer/6006983?hl=zh-Hant)

點選 **Save settings**（儲存設定）後，外觀和語音設定會套用到應用程式及主畫面上所有 Hear Clock 小工具。若要還原，在 **Appearance** 點選 **Restore all defaults**，再點選 **Save settings**。鐘面和語音都會回復預設值。

[返回 Hear Clock 首頁](../README.zh-Hant.md)
