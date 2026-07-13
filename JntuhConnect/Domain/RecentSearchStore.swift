import Foundation
import Observation

struct RecentStudent: Codable, Hashable, Sendable {
    let name: String
    let rollNumber: String
    let branch: String
}

@MainActor
@Observable
final class RecentSearchStore {
    private(set) var students: [RecentStudent] = []
    private let defaults: UserDefaults
    private let key = "recentStudents"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([RecentStudent].self, from: data) {
            students = decoded
        }
    }

    func save(_ student: StudentDetails) {
        let summary = RecentStudent(name: student.name, rollNumber: student.rollNumber, branch: student.branch)
        students.removeAll { $0.rollNumber == summary.rollNumber }
        students.insert(summary, at: 0)
        students = Array(students.prefix(8))
        persist()
    }

    func clear() {
        students.removeAll()
        persist()
    }

    private func persist() {
        defaults.set(try? JSONEncoder().encode(students), forKey: key)
    }
}
