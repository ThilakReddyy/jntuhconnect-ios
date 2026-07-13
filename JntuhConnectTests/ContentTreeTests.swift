import Foundation
import Testing
@testable import JntuhConnect

struct ContentTreeTests {
    @Test func calendarObjectLeavesBecomeDocuments() throws {
        let data = Data(#"{"2025-26":{"B.Tech":{"I Year":{"Academic Calendar":"https://example.com/calendar one.pdf"}}}}"#.utf8)
        let root = try JSONDecoder().decode(ContentNode.self, from: data)

        let node = root.node(at: ["2025-26", "B.Tech", "I Year"])
        #expect(node?.documents?.first?.title == "Academic Calendar")
        #expect(node?.documents?.first?.url.absoluteString == "https://example.com/calendar%20one.pdf")
    }

    @Test func syllabusArrayLeavesDiscardMalformedDocuments() throws {
        let data = Data(#"{"B.Tech":{"R22":{"Computer Science":[{"title":"CSE syllabus","link":"https://example.com/cse.pdf"},{"title":"Missing link"}]}}}"#.utf8)
        let root = try JSONDecoder().decode(ContentNode.self, from: data)

        let documents = root.node(at: ["B.Tech", "R22", "Computer Science"])?.documents
        #expect(documents?.count == 1)
        #expect(documents?.first?.title == "CSE syllabus")
    }

    @Test func officialJNTUHDocumentsUseHTTP() throws {
        let data = Data(#"{"Calendar":"https://results.jntuh.ac.in/calendar.pdf"}"#.utf8)
        let root = try JSONDecoder().decode(ContentNode.self, from: data)

        #expect(root.documents?.first?.url.absoluteString == "http://results.jntuh.ac.in/calendar.pdf")
    }

    @Test func branchPreservesBackendOrderingAndPathLookup() throws {
        let data = Data(#"{"2026":{},"2025":{}}"#.utf8)
        let root = try JSONDecoder().decode(ContentNode.self, from: data)

        #expect(root.entries?.map(\.label) == ["2026", "2025"])
        #expect(root.node(at: ["missing"]) == nil)
    }
}
