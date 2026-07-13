# JNTUH Connect for iOS

Native SwiftUI counterpart to the JNTUH Connect Android app.

## Requirements

- Xcode 26.1+
- XcodeGen 2.45+
- iOS 18+

## Generate and run

```sh
xcodegen generate
open JntuhConnect.xcodeproj
```

## API access configuration

The deployed backend requires the public mobile gateway header `X-Api-Key`. Keep the local value out of source control:

```sh
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
```

Then set `JNTUH_API_KEY` inside `Config/Secrets.xcconfig` and regenerate the project. Xcode expands it into the generated app Info.plist, and `APIRequestFactory` sends it only to the configured JNTUH backend. Never place `GRACE_MARKS_ADMIN_KEY`, database credentials, AWS credentials, or other privileged backend secrets here.

A static mobile access key can be extracted from a distributed app. Before treating this header as a security boundary, the backend should migrate mobile access to App Attest/DeviceCheck or another short-lived token exchange. The current header is suitable only as the same public gateway guard already used by the web client.

## Test

```sh
xcodebuild -project JntuhConnect.xcodeproj \
  -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  test CODE_SIGNING_ALLOWED=NO
```

## Current scope

Implemented natively with Swift 6 concurrency and SwiftUI: three-tab navigation, root-owned pushed-detail navigation, the Obsidian Academic adaptive theme, reusable hall-ticket entry sheets, academic results, all attempts, backlogs, credits, result contrast, academic/backlog class rankings, grace-marks eligibility and proof upload, minimized recent-search persistence, API-wired updates, appearance controls, Dynamic Type-friendly layouts, and VoiceOver labels.

Calendars/PDF viewing, syllabus browsing, careers, channels, Help Center content, and push registration remain explicit non-result parity milestones; the app does not fabricate those flows.
