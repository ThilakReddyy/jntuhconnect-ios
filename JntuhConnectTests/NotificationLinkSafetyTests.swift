import Foundation
import Testing
@testable import JntuhConnect

struct NotificationLinkSafetyTests {
    @Test func officialResultLinkUsesRequiredHTTPTransport() throws {
        let json = #"{"date":"","link":"https://results.jntuh.ac.in/result/123","releaseDate":"Today","title":"Result","category":"results"}"#
        let notification = try JSONDecoder().decode(LatestNotification.self, from: Data(json.utf8))
        #expect(notification.link.absoluteString == "http://results.jntuh.ac.in/result/123")
    }

    @Test func linkPolicyDoesNotDowngradeOtherHosts() throws {
        let secureURL = try #require(URL(string: "https://jntuhconnect.dhethi.com/help"))
        #expect(AppLinkPolicy.browserURL(secureURL) == secureURL)
    }

    @Test func untrustedNotificationHostIsRejected() {
        let json = #"{"date":"","link":"https://evil.example/phish","releaseDate":"Today","title":"Result","category":"results"}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(LatestNotification.self, from: Data(json.utf8))
        }
    }
}
