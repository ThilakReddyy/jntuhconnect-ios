import Foundation
import Observation

struct RecentStudent: Codable, Hashable, Sendable {
    let name: String
    let rollNumber: String
    let branch: String
}

struct RecentDocument: Codable, Hashable, Identifiable, Sendable {
    let title: String
    let url: URL
    let source: String
    let openedAt: Date

    var id: URL { url }
}

@MainActor
@Observable
final class RecentSearchStore {
    private(set) var students: [RecentStudent] = []
    private(set) var documents: [RecentDocument] = []
    private let defaults: UserDefaults
    private let studentKey = "recentStudents"
    private let documentKey = "recentDocuments"
    private let documentLifetime: TimeInterval = 24 * 60 * 60

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        if let data = defaults.data(forKey: studentKey),
           let decoded = try? JSONDecoder().decode([RecentStudent].self, from: data) {
            students = decoded
        }
        if let data = defaults.data(forKey: documentKey),
           let decoded = try? JSONDecoder().decode([RecentDocument].self, from: data) {
            documents = decoded
            removeExpiredDocuments(now: now)
            keepLatestDocumentPerSource()
        }
    }

    func save(_ student: StudentDetails) {
        let summary = RecentStudent(name: student.name, rollNumber: student.rollNumber, branch: student.branch)
        students.removeAll { $0.rollNumber == summary.rollNumber }
        students.insert(summary, at: 0)
        students = Array(students.prefix(8))
        persistStudents()
    }

    func clear() {
        students.removeAll()
        persistStudents()
    }

    func save(_ document: ContentDocument, source: String, now: Date = Date()) {
        removeExpiredDocuments(now: now)
        documents.removeAll { $0.source == source }
        documents.insert(
            RecentDocument(title: document.title, url: document.url, source: source, openedAt: now),
            at: 0
        )
        documents = Array(documents.prefix(2))
        persistDocuments()
    }

    func removeExpiredDocuments(now: Date = Date()) {
        let previousCount = documents.count
        documents.removeAll { now.timeIntervalSince($0.openedAt) >= documentLifetime }
        if documents.count != previousCount {
            persistDocuments()
        }
    }

    func clearDocuments() {
        documents.removeAll()
        persistDocuments()
    }

    private func persistStudents() {
        defaults.set(try? JSONEncoder().encode(students), forKey: studentKey)
    }

    private func persistDocuments() {
        defaults.set(try? JSONEncoder().encode(documents), forKey: documentKey)
    }

    private func keepLatestDocumentPerSource() {
        var seenSources = Set<String>()
        let normalized = documents
            .sorted { $0.openedAt > $1.openedAt }
            .filter { seenSources.insert($0.source).inserted }
            .prefix(2)
        let latestDocuments = Array(normalized)
        if latestDocuments != documents {
            documents = latestDocuments
            persistDocuments()
        }
    }
}
