import Foundation
import Testing
@testable import JntuhConnect

@MainActor
struct RecentSearchPrivacyTests {
    @Test func persistenceKeepsOnlyDisplayedStudentSummary() throws {
        let suite = "RecentSearchPrivacyTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RecentSearchStore(defaults: defaults)

        store.save(StudentDetails(
            collegeCode: "J2",
            fatherName: "Sensitive Parent Name",
            name: "Student",
            rollNumber: "22J21A0501",
            branch: "CSE"
        ))

        let data = try #require(defaults.data(forKey: "recentStudents"))
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("fatherName"))
        #expect(!json.contains("Sensitive Parent Name"))
        #expect(json.contains("22J21A0501"))
    }
}
