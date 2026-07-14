# 📚 JNTUH Connect for iOS

<p align="center">
  <img src="JntuhConnect/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" alt="JNTUH Connect Logo" width="100"/>
</p>

<p align="center">
  <b>Your one-stop native iOS app for JNTUH students — check results, track academic progress, and stay updated.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-000000?style=for-the-badge&logo=apple" alt="Platform iOS"/>
  <img src="https://img.shields.io/badge/Language-Swift%206-F05138?style=for-the-badge&logo=swift" alt="Swift 6"/>
  <img src="https://img.shields.io/badge/UI-SwiftUI-0D96F6?style=for-the-badge&logo=swift" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/Min%20iOS-18.0-green?style=for-the-badge" alt="Minimum iOS 18"/>
  <img src="https://img.shields.io/badge/Version-1.0.0-orange?style=for-the-badge" alt="Version 1.0.0"/>
</p>

<p align="center">
  <a href="https://github.com/ThilakReddyy/jntuhconnect">Android version</a>
  ·
  <a href="https://jntuhconnect.dhethi.com">JNTUH Connect website</a>
</p>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔍 **Result Search** | Search JNTUH results with a validated hall-ticket number and quickly reopen recent students |
| 📊 **Student Results** | View academic summaries, semester performance, subject marks, grades, SGPA, and CGPA |
| 📚 **All Results** | Browse every published regular, supplementary, and RCRV attempt |
| 🎓 **Credits Tracker** | Compare obtained credits with regulation requirements and year-wise progress |
| 🏆 **Class Results** | Rank cleared students by CGPA while separating backlogged and unsynced records |
| ⚖️ **Result Contrast** | Compare the academic performance of two students side by side |
| 📢 **Latest Updates** | Read live JNTUH notifications with All and Results filters |
| 🗓️ **Academic Calendars** | Browse live, drill-down academic calendar trees from the backend |
| 📖 **Syllabus** | Navigate syllabus documents by degree, regulation, branch, and subject |
| 📡 **Channels & Help** | Open useful community channels and built-in support answers |
| 🎨 **Adaptive UI** | Native light/dark themes, Dynamic Type, VoiceOver, and iPhone/iPad layouts |
| 🔒 **Privacy-minded Storage** | Persist only up to eight recent student summaries; result payloads remain in memory |

---

## 🛠️ Tech Stack

| Category | Technology |
|---|---|
| **Language** | Swift 6 |
| **UI Framework** | SwiftUI |
| **Architecture** | Feature-oriented SwiftUI with Domain and Networking layers |
| **State Management** | Observation (`@Observable`, `@Bindable`) |
| **Concurrency** | Swift structured concurrency and an actor-isolated API client |
| **Networking** | URLSession + Codable/JSONDecoder |
| **Navigation** | NavigationStack + TabView |
| **Preferences** | UserDefaults for minimized recent-search summaries |
| **Browser** | SFSafariViewController |
| **Testing** | Swift Testing + XCTest UI tests |
| **Project Generation** | XcodeGen |
| **Dependencies** | No third-party runtime dependencies |

---

## 🏗️ Architecture

The iOS project uses a feature-oriented structure with clear boundaries between app navigation, UI features, domain models, and networking:

```text
JntuhConnect/
│
├── App/                         # App entry point, root tabs, and navigation routes
│
├── Design/                      # Theme, cards, loading UI, and in-app browser
│
├── Domain/                      # Result, content, roll-number, and persistence models
│
├── Features/                    # User-facing SwiftUI features
│   ├── Home/                    # Hall-ticket search and recent students
│   ├── Results/                 # Results, credits, contrast, and class reports
│   ├── Explore/                 # Tools, calendars, syllabus, channels, and help
│   ├── Updates/                 # Live JNTUH notifications
│   └── Profile/                 # Appearance, local data, support, and about settings
│
├── Networking/                  # API client, endpoints, requests, and response handling
│
└── Resources/                   # App assets, Info.plist, and privacy manifest

JntuhConnectTests/               # Unit and opt-in live integration tests
JntuhConnectUITests/             # End-to-end, adaptive-layout, and visual UI tests
```

The primary data flow is:

```text
SwiftUI View → @Observable Store → APIClient actor → Endpoint/APIRequestFactory
                                             ↓
                                  Decodable domain models
```

`RootView` owns the shared `NavigationStack`, three adaptive root tabs, recent-search store, and pushed routes. Tabs stay at the bottom on iPhone and use Apple’s adaptable top-bar/sidebar treatment on iPad. Feature stores own loading, pending, unavailable, success, and error states. The shared `APIClient` actor owns its ephemeral URLSession and JSON decoder.

---

## 🌐 API

The app communicates with the JNTUH Connect backend at:

```text
https://jntuhresults.dhethi.com/api/
```

### Key Endpoints

| Endpoint | Description |
|---|---|
| `GET /getAcademicResult?rollNumber=` | Fetch consolidated academic results |
| `GET /getAllResult?rollNumber=` | Fetch every published semester attempt |
| `GET /getBacklogs?rollNumber=` | Fetch active backlog subjects |
| `GET /getCreditsChecker?rollNumber=` | Fetch obtained and required credits |
| `GET /getResultContrast?rollNumber1=&rollNumber2=` | Compare two students |
| `GET /getClassResults?rollNumber=&type=` | Fetch academic or backlog class data |
| `GET /notifications?page=&category=` | Fetch paginated JNTUH updates |
| `GET /calendars` | Fetch the academic calendar tree |
| `GET /syllabus` | Fetch the syllabus tree |

Requests require the public mobile gateway header `X-Api-Key`. See the setup instructions below to configure it locally.

---

## 🚀 Getting Started

### Prerequisites

- macOS with **Xcode 26.1** or later
- **XcodeGen 2.45** or later
- An iOS **18.0+** simulator or device
- A public mobile gateway key for the JNTUH Connect API

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/ThilakReddyy/jntuhconnect-ios.git
   cd jntuhconnect-ios
   ```

2. **Install XcodeGen**

   ```bash
   brew install xcodegen
   ```

3. **Create the local API configuration**

   ```bash
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```

4. **Add the public gateway key**

   ```xcconfig
   JNTUH_API_KEY = your-public-mobile-access-key
   ```

5. **Generate and open the project**

   ```bash
   xcodegen generate
   open JntuhConnect.xcodeproj
   ```

6. **Build and run**

   - Select the `JntuhConnect` scheme.
   - Choose an iOS 18+ simulator and click ▶️ **Run**.
   - For a physical device, select your Apple development team in Xcode.

`Config/Secrets.xcconfig` is ignored by Git. Regenerate the Xcode project after changing `project.yml` or project configuration files.

---

## 📱 Navigation

The app is organized into **three tabs**, with result details and resources pushed from a shared navigation stack:

| Tab | Description |
|---|---|
| 🏠 **Home** | Search a hall-ticket number, open unified student results, and revisit recent students |
| 🧭 **Explore** | Access result tools, class analysis, updates, calendars, syllabus, channels, and help |
| ⚙️ **Settings** | Change appearance, clear local recent searches, open support, and view app information |

---

## 📦 Build Configuration

| Property | Value |
|---|---|
| Product Bundle ID | `com.dhethi.jntuhconnect.ios` |
| Deployment Target | iOS 18.0 |
| Swift Version | 6.0 |
| Marketing Version | 1.0.0 |
| Build Number | 1 |
| Supported Devices | iPhone and iPad |
| Project Source of Truth | `project.yml` |

### Command-line Build

```bash
xcodebuild \
  -project JntuhConnect.xcodeproj \
  -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  build CODE_SIGNING_ALLOWED=NO
```

Replace the simulator name and OS version with any installed destination that supports iOS 18 or later.

---

## 🧪 Testing

Run the complete unit and UI test suite:

```bash
xcodebuild \
  -project JntuhConnect.xcodeproj \
  -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  test CODE_SIGNING_ALLOWED=NO
```

Run only the unit tests:

```bash
xcodebuild \
  -project JntuhConnect.xcodeproj \
  -scheme JntuhConnect \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  -only-testing:JntuhConnectTests \
  test CODE_SIGNING_ALLOWED=NO
```

The live integration test is opt-in through `RUN_LIVE_API_TESTS=1`. Several UI tests also load live result data, so they require network access and a valid gateway key.

---

## 🔐 Security & Privacy

- The app uses an ephemeral URLSession with no URL cache for API requests.
- Academic result responses are kept in memory and are not persisted by the app.
- Only up to eight recent student summaries—name, hall-ticket number, and branch—are saved in UserDefaults.
- Recent searches can be removed at any time from Settings.
- The app contains no document, photo, or video upload feature.
- The privacy manifest declares UserDefaults access and hall-ticket numbers used for result requests; app tracking is disabled.
- Document links are restricted to HTTP/HTTPS and opened with SFSafariViewController.

See the user-facing [privacy policy](PRIVACY.md) and the [App Store compliance checklist](APP_STORE_COMPLIANCE.md) before preparing a release.

The mobile `X-Api-Key` is a public gateway value, not a durable security boundary; any static key distributed in an app can be extracted. Never add admin keys, database credentials, cloud credentials, signing material, or other privileged backend secrets to this project.

---

## 🤝 Contributing

Contributions are welcome! If you would like to improve the iOS app:

1. Fork the repository.
2. Create a branch: `git checkout -b feature/your-feature-name`.
3. Commit your changes: `git commit -m 'Add some feature'`.
4. Push the branch: `git push origin feature/your-feature-name`.
5. Open a pull request.

Please run the relevant unit and UI tests before submitting changes. Do not commit `Config/Secrets.xcconfig`, Xcode user data, screenshots, test artifacts, or credentials.

---

## ⚠️ Disclaimer

JNTUH Connect is a community project and is not an official application of Jawaharlal Nehru Technological University Hyderabad. Result availability and accuracy depend on data published by JNTUH and the JNTUH Connect backend. Records that are pending or not synced are shown separately where supported.

---

## 👨‍💻 Author

**Thilak Reddy**<br>
GitHub: [@ThilakReddyy](https://github.com/ThilakReddyy)

---

<p align="center">Made with ❤️ for JNTUH Students</p>
