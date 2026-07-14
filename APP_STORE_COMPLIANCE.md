# App Store implementation notes

Reviewed against Apple guidance available on July 14, 2026. This document records the App Store readiness features implemented in the iOS project.

## iPhone and iPad support

- The app builds with Xcode 26 and the iOS 26 SDK while supporting iOS 18 and later.
- `TARGETED_DEVICE_FAMILY` includes iPhone and iPad.
- The app includes a launch-screen declaration and supports every iPad orientation.
- Width-responsive SwiftUI layouts adapt content for compact and regular-width screens.
- Root navigation uses Apple's `sidebarAdaptable` tab style, providing bottom tabs on iPhone and an adaptive tab bar or sidebar on iPad.
- `WindowGroup`, scene-scoped tab selection, and `UIApplicationSupportsMultipleScenes` support independent iPad windows.
- Dynamic Type-aware layouts improve usability across accessibility text sizes.

## Privacy and data handling

- The privacy manifest declares UserDefaults required-reason API use and confirms that tracking is disabled.
- Hall-ticket numbers are declared as user identifiers used for app functionality.
- The app contains no document, photo, or video upload flow.
- The app requests no protected-resource permissions.
- The app contains no advertising or analytics SDK.
- The app has no account system, social login, or in-app purchases.
- Settings provides an in-app privacy explanation, a published privacy policy, support access, and controls for clearing local data.
- External content opens visibly in `SFSafariViewController`.
- Notification links are restricted to the expected university host.
- Network requests use Apple-provided networking APIs, with no custom cryptography.

## App experience

- Navigation and content layouts support compact iPhones, larger iPhones, iPad portrait and landscape, and resizable iPad windows.
- Result, resource, notification, and settings experiences use native SwiftUI components.
- Empty, loading, queued, failure, and populated states provide clear user feedback.
- Recent-document shortcuts are stored locally and can be cleared by the user.

## Verification coverage

- Property-list validation covers `Info.plist` and `PrivacyInfo.xcprivacy`.
- Unit tests cover networking, decoding, validation, link handling, persistence, and presentation behavior.
- UI tests exercise core privacy behavior on representative iPhone and iPad simulators.
- Release builds verify production compilation with code signing disabled for local validation.
- The privacy policy, support page, and product website are publicly accessible.

## Privacy-manifest mapping

| Data | Linked | Tracking | Purpose | Trigger |
|---|---:|---:|---|---|
| User ID (hall-ticket number) | Yes | No | App Functionality | Result requests |

## Apple references

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Upcoming submission requirements](https://developer.apple.com/news/upcoming-requirements/)
- [Privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Designing for iPadOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados)
- [Multitasking](https://developer.apple.com/design/human-interface-guidelines/multitasking)
- [Migrating away from UIRequiresFullScreen](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key)
