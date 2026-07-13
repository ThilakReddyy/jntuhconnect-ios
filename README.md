# JNTUH Connect for iOS

JNTUH Connect is a native SwiftUI app that gives Jawaharlal Nehru Technological University Hyderabad students one place to view academic results, analyze performance, and browse university resources.

This repository contains the iPhone and iPad counterpart to JNTUH Connect for Android. It is a community project and is not an official JNTUH application.

## Highlights

- Search by a validated 10-character hall-ticket number.
- View academic summaries, semester results, every published attempt, active backlogs, and earned credits.
- Compare the results of two students.
- Review academic and backlog data for a class.
- Check initial grace-marks eligibility and upload supporting proof.
- Browse JNTUH notifications, academic calendars, and syllabus documents.
- Open community channels and built-in help content.
- Keep up to eight recent students on-device for quick access.
- Choose system, light, or dark appearance.
- Use layouts designed for iPhone, iPad, Dynamic Type, and VoiceOver.

## Technology

- Swift 6
- SwiftUI and Observation
- Structured concurrency with an actor-isolated API client
- URLSession with ephemeral, non-caching network configuration
- Swift Testing for unit and integration tests
- XCTest for end-to-end UI tests
- XcodeGen for reproducible project generation
- No third-party runtime dependencies

## Requirements

- macOS with Xcode 26.1 or newer
- XcodeGen 2.45 or newer
- An iOS 18 or newer simulator/device
- A public mobile gateway key for the JNTUH Connect API

The deployment target is iOS 18.0. The test command below uses the iPhone 17 Pro simulator on iOS 26.1; substitute any installed simulator that meets the deployment target.

## Getting started

1. Clone the repository and enter it:

   ```sh
   git clone git@github.com:ThilakReddyy/jntuhconnect-ios.git
   cd jntuhconnect-ios
   ```

2. Install XcodeGen if it is not already available:

   ```sh
   brew install xcodegen
   ```

3. Create the local API configuration:

   ```sh
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```

4. Set the public gateway key in `Config/Secrets.xcconfig`:

   ```xcconfig
   JNTUH_API_KEY = your-public-mobile-access-key
   ```

5. Generate and open the Xcode project:

   ```sh
   xcodegen generate
   open JntuhConnect.xcodeproj
   ```

6. Select the `JntuhConnect` scheme and run it on an iOS 18+ simulator. To use a physical device, select an appropriate development team and signing identity in Xcode.

The generated app configuration expands `JNTUH_API_KEY` into the `JNTUHAPIKey` Info.plist value. `APIRequestFactory` sends it as `X-Api-Key` only to the configured JNTUH Connect backend.

## Build from the command line

```sh
xcodebuild \
  -project JntuhConnect.xcodeproj \
  -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  build CODE_SIGNING_ALLOWED=NO
```

If `project.yml` changes, run `xcodegen generate` before building so the checked-in Xcode project stays in sync.

## Tests

Run the complete unit and UI test suite:

```sh
xcodebuild \
  -project JntuhConnect.xcodeproj \
  -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  test CODE_SIGNING_ALLOWED=NO
```

Run only the unit tests:

```sh
xcodebuild \
  -project JntuhConnect.xcodeproj \
  -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  -only-testing:JntuhConnectTests \
  test CODE_SIGNING_ALLOWED=NO
```

Some UI and live integration tests contact the deployed backend, so they require network access and a valid API key.

## App structure

| Path | Responsibility |
| --- | --- |
| `JntuhConnect/App` | App entry point, root tabs, and navigation |
| `JntuhConnect/Design` | Theme, reusable visual styles, and in-app browser |
| `JntuhConnect/Domain` | Result, content, roll-number, and persistence models |
| `JntuhConnect/Features/Home` | Hall-ticket search and recent students |
| `JntuhConnect/Features/Results` | Student results, class analysis, contrast, and grace marks |
| `JntuhConnect/Features/Explore` | Tools, calendars, syllabus, channels, and help |
| `JntuhConnect/Features/Updates` | Paginated JNTUH notifications |
| `JntuhConnect/Features/Profile` | Appearance, local-data controls, and app information |
| `JntuhConnect/Networking` | Endpoints, request construction, response validation, and API client |
| `JntuhConnectTests` | Unit and opt-in live API integration tests |
| `JntuhConnectUITests` | User-flow, adaptive-layout, and visual UI tests |
| `project.yml` | XcodeGen source of truth |

The app uses a root-owned `NavigationStack` around a three-tab interface. Feature stores own loading and error state, while the shared `APIClient` actor serializes access to the JSON decoder and network session. Result payloads stay in memory; only a minimized recent-student summary is persisted.

## API and security notes

`Config/Secrets.xcconfig` is intentionally ignored by Git. Never commit real keys or replace the example value with a working credential.

The mobile `X-Api-Key` is a public gateway value, not a durable security boundary: any static key shipped in an app can be extracted. Do not place `GRACE_MARKS_ADMIN_KEY`, database credentials, AWS credentials, signing material, or other privileged backend secrets in this project. Sensitive backend operations should use App Attest, DeviceCheck, or another short-lived token exchange.

The API client:

- Talks to `https://jntuhresults.dhethi.com/api/`.
- Uses an ephemeral URLSession without a response cache.
- Applies request and resource timeouts.
- Maps offline, timeout, rate-limit, pending-result, HTTP, and decoding failures to user-facing states.
- Restricts document links to HTTP/HTTPS and routes supported links through the in-app browser.
- Accepts grace-proof PDF, PNG, and JPEG files up to 5 MB.

## Privacy

- The app does not enable tracking.
- Academic result responses are not persisted by the app.
- Up to eight recent student summaries—name, hall-ticket number, and branch—are stored in UserDefaults on the device and can be cleared from Settings.
- Grace-mark proof files are uploaded only after the user explicitly selects and submits a file.
- The included privacy manifest declares UserDefaults access.

Review the backend's privacy and retention policies before distributing a production build.

## Supported scope

The current app includes native result flows, class analysis, grace-marks proof upload, live updates, academic calendar and syllabus browsers, community links, help content, appearance controls, accessibility support, and adaptive iPad layouts.

The experience depends on data published by JNTUH and the availability and shape of the JNTUH Connect API. Results may be pending or partially synced, and the app presents those records separately instead of treating missing data as an academic result.

## Troubleshooting

- **“Missing public API access configuration”**: create `Config/Secrets.xcconfig`, set `JNTUH_API_KEY`, and regenerate the project.
- **Project settings look stale**: run `xcodegen generate` after changing `project.yml` or configuration files.
- **Simulator destination not found**: run `xcrun simctl list devices available` and replace the destination in the build/test command.
- **Signing fails on a physical device**: configure your Apple development team and use a bundle identifier available to that team.
- **Live tests fail while unit tests pass**: confirm the network is available and the gateway key is valid.
