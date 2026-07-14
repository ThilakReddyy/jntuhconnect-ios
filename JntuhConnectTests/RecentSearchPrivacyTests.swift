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

    @Test func documentShortcutsExpireAfter24Hours() throws {
        let suite = "RecentDocumentExpiryTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let openedAt = Date(timeIntervalSince1970: 1_000_000)
        let document = ContentDocument(
            title: "B.Tech Academic Calendar",
            url: try #require(URL(string: "https://example.com/calendar.pdf"))
        )
        let store = RecentSearchStore(defaults: defaults, now: openedAt)

        store.save(document, source: "Calendars", now: openedAt)
        #expect(store.documents.count == 1)

        let reloaded = RecentSearchStore(
            defaults: defaults,
            now: openedAt.addingTimeInterval(24 * 60 * 60)
        )
        #expect(reloaded.documents.isEmpty)
        let persistedData = try #require(defaults.data(forKey: "recentDocuments"))
        let persistedDocuments = try JSONDecoder().decode([RecentDocument].self, from: persistedData)
        #expect(persistedDocuments.isEmpty)
    }

    @Test func newerDocumentReplacesShortcutFromSameSource() throws {
        let suite = "RecentDocumentRefreshTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let firstOpen = Date(timeIntervalSince1970: 1_000_000)
        let secondOpen = firstOpen.addingTimeInterval(60)
        let firstDocument = ContentDocument(
            title: "R22 CSE Syllabus",
            url: try #require(URL(string: "https://example.com/r22-cse.pdf"))
        )
        let secondDocument = ContentDocument(
            title: "R23 ECE Syllabus",
            url: try #require(URL(string: "https://example.com/r23-ece.pdf"))
        )
        let store = RecentSearchStore(defaults: defaults, now: firstOpen)

        store.save(firstDocument, source: "Syllabus", now: firstOpen)
        store.save(secondDocument, source: "Syllabus", now: secondOpen)

        #expect(store.documents.count == 1)
        #expect(store.documents.first?.title == "R23 ECE Syllabus")
        #expect(store.documents.first?.url == secondDocument.url)
        #expect(store.documents.first?.openedAt == secondOpen)
    }

    @Test func calendarAndSyllabusKeepSeparateShortcuts() throws {
        let suite = "RecentDocumentSourceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date(timeIntervalSince1970: 1_000_000)
        let calendar = ContentDocument(
            title: "Academic Calendar",
            url: try #require(URL(string: "https://example.com/calendar.pdf"))
        )
        let syllabus = ContentDocument(
            title: "CSE Syllabus",
            url: try #require(URL(string: "https://example.com/syllabus.pdf"))
        )
        let store = RecentSearchStore(defaults: defaults, now: now)

        store.save(calendar, source: "Calendars", now: now)
        store.save(syllabus, source: "Syllabus", now: now.addingTimeInterval(1))

        #expect(store.documents.count == 2)
        #expect(Set(store.documents.map(\.source)) == ["Calendars", "Syllabus"])
    }
}
