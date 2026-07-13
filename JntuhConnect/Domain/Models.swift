import Foundation

struct StudentDetails: Codable, Hashable, Sendable {
    let collegeCode: String
    let fatherName: String
    let name: String
    let rollNumber: String
    let branch: String
}

struct AcademicResultResponse: Codable, Sendable {
    let details: StudentDetails?
    let results: AcademicResult
}

struct AcademicResult: Codable, Sendable {
    let backlogs: Int
    let cgpa: String
    let credits: Double
    let grades: Double
    let semesters: [Semester]

    enum CodingKeys: String, CodingKey {
        case backlogs, credits, grades, semesters
        case cgpa = "CGPA"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        backlogs = try container.decode(Int.self, forKey: .backlogs)
        credits = try container.decode(Double.self, forKey: .credits)
        grades = try container.decode(Double.self, forKey: .grades)
        semesters = try container.decode([Semester].self, forKey: .semesters)

        if let value = try? container.decode(String.self, forKey: .cgpa) {
            cgpa = value
        } else {
            let value = try container.decode(Double.self, forKey: .cgpa)
            cgpa = value.rounded() == value ? String(Int(value)) : String(value)
        }
    }
}

struct Semester: Codable, Identifiable, Sendable {
    let backlogs: Double
    let failed: Bool
    let semester: String
    let semesterCredits: Double
    let semesterGrades: Double
    let semesterSGPA: String
    let subjects: [Subject]

    var id: String { semester }
}

struct Subject: Codable, Identifiable, Sendable {
    let credits: Double
    let externalMarks: Int
    let grade: String
    let internalMarks: Int
    let subjectCode: String
    let subjectName: String
    let totalMarks: Int

    var id: String { subjectCode }

    enum CodingKeys: String, CodingKey {
        case credits, externalMarks, internalMarks, subjectCode, subjectName, totalMarks
        case grade = "grades"
    }
}

struct LatestNotification: Codable, Identifiable, Sendable {
    let date: String
    let link: URL
    let releaseDate: String
    let title: String
    let category: String

    var id: String { link.absoluteString + title }

    enum CodingKeys: String, CodingKey { case date, link, releaseDate, title, category }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        releaseDate = try container.decode(String.self, forKey: .releaseDate)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)

        let rawLink = try container.decode(String.self, forKey: .link)
        guard var components = URLComponents(string: rawLink),
              components.host?.lowercased() == "results.jntuh.ac.in",
              ["http", "https"].contains(components.scheme?.lowercased() ?? "") else {
            throw DecodingError.dataCorruptedError(
                forKey: .link,
                in: container,
                debugDescription: "Untrusted notification link"
            )
        }
        components.scheme = "http"
        guard let safeURL = components.url else {
            throw DecodingError.dataCorruptedError(forKey: .link, in: container, debugDescription: "Invalid notification link")
        }
        link = safeURL
    }
}
