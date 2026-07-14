import Foundation

enum AppInformation {
    static let websiteURL = URL(string: "https://jntuhconnect.dhethi.com")!
    static let privacyPolicyURL = URL(
        string: "https://github.com/ThilakReddyy/jntuhconnect-ios/blob/main/PRIVACY.md"
    )!
    static let supportURL = URL(
        string: "https://github.com/ThilakReddyy/jntuhconnect-ios/issues"
    )!

    static var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }
}
