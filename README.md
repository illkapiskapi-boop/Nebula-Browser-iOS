# ☄ Nebula Browser for iOS

**Browse beyond the ordinary.**  
A violet nebula-inspired browser for iPhone and iPad, built natively with UIKit and Apple's WebKit (`WKWebView`).

> **Compatibility note:** this project is configured for **iOS 15–27** using the current Xcode 27 toolchain. It does **not** support iOS 11–14. Xcode 27's documented deployment-target range is iOS 15–27. Older iOS 11–14 support would require a separate legacy toolchain/project and cannot be combined into the same current Xcode 27 build. Apple's current App Store upload rules also require iOS 13 or later. See the official sources linked below.

## Features

- Dark violet Nebula interface with rounded controls and a subtle animated glow.
- Three appearance themes: Violet, Aurora Blue, and Cosmic Rose.
- DuckDuckGo search and URL bar.
- Multi-tab browsing with create, switch, and close actions.
- Browsing history with search, individual deletion, and clear-all.
- Bookmarks with delete and open actions.
- File downloads to the app's Documents/Downloads folder, followed by the iOS share sheet.
- Browser data stored locally in the app's Application Support folder.
- Memory-conscious tab model: only the active `WKWebView` is kept alive. Other tabs store their last URL/title and reload when selected.

### Memory behavior

To reduce memory usage, Nebula keeps one active WebKit view at a time. Switching tabs saves the current tab's address and title, then recreates the WebKit view for the selected tab. This means the site reloads when you switch back; unsaved form contents and the page's internal back/forward state may not be preserved.

### Web engine

This iOS version uses Apple's `WKWebView` (WebKit). It does not bundle Chromium. This is the normal WebKit-based approach for browser apps distributed through the standard iOS App Store rules.

## Requirements

- A Mac that can run Xcode 27.2 (Apple's current Xcode 27 line requires macOS Tahoe 26.6 or later).
- Xcode 27.2 or a compatible Xcode 27 release.
- An iPhone/iPad running iOS/iPadOS 15 or later for device testing.
- An Apple Developer account and signing configuration for distribution to physical devices/TestFlight/App Store.

## Build in Xcode

1. Download and extract this repository on a Mac.
2. Open `NebulaBrowser.xcodeproj` in Xcode.
3. Select the `NebulaBrowser` scheme.
4. In **Signing & Capabilities**, choose your Apple development team. For a personal test build, use your own Apple ID in Xcode's Accounts settings and choose a unique Bundle Identifier.
5. Choose an iPhone/iPad simulator or a connected device.
6. Press **Run** (`⌘R`).

The app uses automatic signing. Before publishing, replace `com.nebulabrowser.ios` with a bundle identifier you control.

## Build with one script

### On a Mac

Double-click `build-ios-mac.sh` from Terminal (or run `./build-ios-mac.sh`). It builds the iOS Simulator `.app` and keeps the terminal open to show the result. The output is:

```text
build/Build/Products/Debug-iphonesimulator/NebulaBrowser.app
```

### On Windows

Double-click `build-ios-windows.bat`. It opens a persistent Command Prompt window, checks GitHub CLI and authentication, starts the included GitHub Actions workflow on a GitHub-hosted macOS runner, waits for the build, and downloads the artifact to `build-output`. The window stays open at the end so errors remain visible.

Before running the BAT:

1. Create a separate GitHub repository for the iOS project.
2. Upload the contents of this project folder, including `.github/workflows/ios-build.yml`.
3. Install GitHub CLI from <https://cli.github.com/> and sign in once with `gh auth login`.
4. Run `build-ios-windows.bat` and enter `owner/repository` when prompted.

**Important:** both scripts currently produce an iOS Simulator `.app`. It is not an installable iPhone `.ipa`. Building a signed device `.ipa` requires macOS/Xcode plus an Apple signing identity and provisioning profile (or properly configured signing secrets on a remote macOS runner).

## Project layout

```text
NebulaBrowser-iOS/
├── NebulaBrowser.xcodeproj/
├── NebulaBrowser/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── BrowserViewController.swift
│   ├── BrowserDataStore.swift
│   ├── LibraryViewController.swift
│   ├── SettingsViewController.swift
│   ├── Info.plist
│   ├── PrivacyInfo.xcprivacy
│   ├── LaunchScreen.storyboard
│   └── Assets.xcassets/
├── .github/workflows/ios-build.yml
├── build-ios-mac.sh
└── build-ios-windows.bat
```

## Current platform limitation

A single current Xcode 27 app target cannot cover iOS 11 through iOS 27. Xcode 27 documents deployment targets from iOS 15 through iOS 27. This project therefore targets iOS 15 as the broadest supported range in the current toolchain. A separate old-toolchain legacy build would be needed for iOS 11–14; that legacy build would not be the same App Store-ready iOS 27 build.

Official Apple references:

- [Xcode system requirements and deployment target ranges](https://developer.apple.com/xcode/system-requirements/)
- [Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes)
- [App Store upcoming submission requirements](https://developer.apple.com/news/upcoming-requirements/)

---

## Русский

### Nebula Browser для iPhone и iPad

**Исследуй интернет за пределами обыденного.** Nebula Browser — мобильный браузер с тёмным фиолетовым оформлением, скруглёнными элементами, свечением и настройками внешнего вида. Приложение использует UIKit и системный WebKit (`WKWebView`).

**Возможности:**
- Фиолетовая тема Nebula и варианты Aurora Blue / Cosmic Rose.
- DuckDuckGo как поисковик по умолчанию.
- Вкладки: создание, переключение и закрытие.
- История посещений: поиск, удаление записей и полная очистка.
- Закладки.
- Загрузка файлов и передача через системное меню iOS.
- Локальное сохранение истории, закладок и открытых вкладок.
- Экономия памяти: одновременно активен только один `WKWebView`, остальные вкладки открываются заново по сохранённому адресу.

**Важно о памяти:** при переключении вкладки её страница загружается заново. Незавершённые формы и внутреннее состояние страницы могут не сохраниться.

### Совместимость iOS

Этот проект настроен на **iOS 15–27**. Поддержку iOS 11–14 нельзя включить в тот же современный проект Xcode 27: официальный диапазон deployment target для Xcode 27 начинается с iOS 15. Для iOS 11–14 потребовалась бы отдельная сборка на старом Xcode и старом SDK. Это не будет тем же современным App Store build.

### Сборка

Для сборки нужен **Mac с Xcode 27.2**. Открой `NebulaBrowser.xcodeproj`, выбери схему `NebulaBrowser`, укажи свою команду разработчика в **Signing & Capabilities** и нажми `Run` (`⌘R`). Для установки на реальный iPhone или публикации нужен Apple signing/provisioning profile. На Windows напрямую собрать или подписать iOS-приложение через Xcode нельзя.

*Explore the web. Discover your universe.*  
*Исследуй интернет. Открой свою вселенную.* 💜
