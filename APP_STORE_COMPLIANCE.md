# App Store compliance and release checklist

Audited against Apple guidance available on July 14, 2026. App Review is a human process and Apple’s rules change, so this document records evidence and release gates; it is not a guarantee of approval.

## Source and bundle controls present

- The app builds with Xcode 26 and the iOS 26 SDK, while supporting iOS 18 and later.
- `TARGETED_DEVICE_FAMILY` includes iPhone and iPad.
- The app has a launch-screen declaration, supports every iPad orientation, does not opt out through `UIRequiresFullScreen`, and uses width-responsive SwiftUI layouts.
- Root navigation uses Apple’s `sidebarAdaptable` tab style: bottom tabs on iPhone and a top tab bar/sidebar on iPad.
- `WindowGroup`, scene-scoped tab selection, and `UIApplicationSupportsMultipleScenes` support multiple independent iPad windows.
- The privacy manifest declares UserDefaults required-reason API use, tracking disabled, and hall-ticket numbers used for result requests.
- The app contains no document, photo, or video picker/upload path and requests no protected-resource permission.
- The app has no advertising, analytics SDK, account system, social login, in-app purchase, or protected-resource permission request.
- Settings provides an in-app privacy/data explanation, a published policy link, support, an independent-app disclaimer, and controls to clear local data.
- External API traffic uses HTTPS. External content opens visibly in `SFSafariViewController`; notification URLs are restricted to the expected university host.
- The app declares that it does not use non-exempt encryption, based on its use of Apple-provided HTTPS APIs and no custom cryptography.

## Blocking evidence required before submission

These cannot be proven or solved by the iOS repository alone. Do not submit until every item is resolved.

- [ ] **Student-data authority and consent:** Apple Guideline 5.1.1(viii) prohibits apps that compile personal information from public or other sources without the person’s explicit consent. This app displays names and academic records and its class/contrast tools can display other students. Obtain documented legal/university authority and an App Review-ready explanation, add a reliable subject authorization mechanism, or remove the affected features from the App Store build.
- [ ] **JNTUH content and trademark rights:** Obtain written permission or verify terms that specifically allow the app to access, reproduce, and display JNTUH data, documents, name, and marks. Apple may request proof under Guidelines 5.2.1 and 5.2.2.
- [ ] **Backend retention and deletion:** Confirm that production behavior matches `PRIVACY.md`, document actual result-query retention, and ensure maintainers can authenticate and complete deletion requests. Replace the public-issue handoff with a private, monitored privacy contact when available.
- [ ] **Publish the privacy policy:** Push `PRIVACY.md` to the public repository and verify the exact in-app URL without authentication. Add the same URL to App Store Connect.
- [ ] **Match App Store privacy answers:** At minimum review User ID, linked to the user, not used for tracking, and used for App Functionality. Include any backend or infrastructure practices not visible in this repository.
- [ ] **Provide durable support contact:** Confirm the App Support URL is public, monitored, and offers a private escalation path. Keep developer contact information current in App Store Connect.
- [ ] **Use authorized or fictional screenshots:** Do not submit screenshots containing a real student’s name, hall ticket number, marks, or academic history without written permission. Build sanitized fixtures for App Store screenshots.
- [ ] **Complete current metadata:** Accurate description, screenshots for the submitted device classes, keywords, category, copyright, “What’s New,” updated age-rating answers, Content Rights declaration, and territory-specific compliance such as DSA trader status.
- [ ] **Review access:** Keep the backend available and provide App Review notes with authorized test data or a fully featured, sanitized review mode. Explain queued requests and data sources.
- [ ] **Accessibility verification:** Run Accessibility Inspector and manual VoiceOver, Voice Control, Larger Text, Dark Interface, Differentiate Without Color Alone, Sufficient Contrast, and Reduced Motion checks on representative iPhone and iPad windows before claiming App Store accessibility labels.
- [ ] **Device and failure testing:** Test a small iPhone, current iPhone, iPad portrait/landscape, narrow and wide resizable iPad windows, offline mode, slow service, malformed backend data, and memory pressure.

## Privacy-manifest/App Store Connect mapping

| Data | Linked | Tracking | Purpose | Trigger |
|---|---:|---:|---|---|
| User ID (hall ticket number) | Yes | No | App Functionality | Result requests |

If the backend keeps query history, diagnostics, IP addresses, support data, or other information beyond servicing a real-time request, add the corresponding App Store data types and update the policy before submission.

## Release verification commands

```sh
plutil -lint JntuhConnect/Resources/Info.plist
plutil -lint JntuhConnect/Resources/PrivacyInfo.xcprivacy
xcodegen generate
xcodebuild -project JntuhConnect.xcodeproj -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  test CODE_SIGNING_ALLOWED=NO
xcodebuild -project JntuhConnect.xcodeproj -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.1' \
  test CODE_SIGNING_ALLOWED=NO
```

Before uploading, create a Release archive with the required current Xcode/SDK, validate it in Organizer, inspect its privacy report, and resolve every warning.

## Apple references

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Upcoming submission requirements](https://developer.apple.com/news/upcoming-requirements/)
- [Privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Designing for iPadOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados)
- [Multitasking](https://developer.apple.com/design/human-interface-guidelines/multitasking)
- [Migrating away from UIRequiresFullScreen](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key)
