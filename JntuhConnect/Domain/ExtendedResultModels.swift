import Foundation

struct AllResultsResponse: Decodable, Sendable {
    let details: StudentDetails
    let results: [AllResultSemester]
}

struct AllResultSemester: Decodable, Identifiable, Sendable {
    let semester: String
    let exams: [ExamAttempt]
    var id: String { semester }
}

struct ExamAttempt: Decodable, Identifiable, Sendable {
    let examCode: String
    let rcrv: Bool
    let graceMarks: Bool
    let subjects: [Subject]
    var id: String { examCode + String(rcrv) + String(graceMarks) }
}

struct BacklogResponse: Decodable, Sendable {
    let details: StudentDetails
    let results: BacklogSummary
}

struct BacklogSummary: Decodable, Sendable {
    let semesters: [Semester]
    let totalBacklogs: Int
}

struct CreditsResponse: Decodable, Sendable {
    let details: StudentDetails?
    let results: CreditsSummary?
    let status: String?
    let message: String?
}

struct CreditsSummary: Decodable, Sendable {
    let academicYears: [AcademicYearCredits]
    let totalCredits: Double
    let totalObtainedCredits: Double
    let totalRequiredCredits: Double
}

struct AcademicYearCredits: Decodable, Sendable {
    let semesterWiseCredits: [String: Double]
    let creditsObtained: Double
    let totalCredits: Double
}

struct ResultContrastResponse: Decodable, Sendable {
    let studentProfiles: [ContrastProfile]
    let semesters: [[ContrastSemester]]
}

struct ContrastProfile: Decodable, Identifiable, Sendable {
    let name: String
    let rollNumber: String
    let collegeCode: String
    let fatherName: String
    private let CGPA: ScalarText
    let backlogs: Double
    let credits: Double

    var id: String { rollNumber }
    var cgpa: String { CGPA.value }
}

struct ContrastSemester: Decodable, Identifiable, Sendable {
    let semester: String
    let semesterSGPA: ScalarText
    let semesterCredits: ScalarText
    let semesterGrades: ScalarText
    let backlogs: ScalarText
    let failed: Bool

    var id: String { semester }
    var sgpa: String { semesterSGPA.value }
    var credits: String { semesterCredits.value }
}

struct ClassResultStudent: Decodable, Identifiable, Sendable {
    let details: StudentDetails
    let results: AcademicResult?
    var id: String { details.rollNumber }

    enum CodingKeys: String, CodingKey { case details, results }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        details = try container.decode(StudentDetails.self, forKey: .details)
        results = try? container.decode(AcademicResult.self, forKey: .results)
    }
}

struct ClassBacklogStudent: Decodable, Identifiable, Sendable {
    let details: StudentDetails
    let results: BacklogSummary?
    var id: String { details.rollNumber }

    enum CodingKeys: String, CodingKey { case details, results }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        details = try container.decode(StudentDetails.self, forKey: .details)
        results = try? container.decode(BacklogSummary.self, forKey: .results)
    }
}

struct GraceEligibilityResponse: Decodable, Sendable {
    let status: String?
    let message: String?
    let semesters: [Semester]?
    let totalBacklogs: Int?

    var isEligible: Bool { semesters != nil }
}

struct GraceProofUploadResponse: Decodable, Sendable {
    let status: String
    let rollNumber: String
    let downloadUrl: String
    let uploadedAt: String
}

enum GraceProofFile {
    static let maximumSize = 5 * 1024 * 1024
    static let supportedMIMETypes = ["application/pdf", "image/png", "image/jpeg", "image/jpg"]

    static func validate(size: Int, mimeType: String) throws {
        guard size > 0, size <= maximumSize, supportedMIMETypes.contains(mimeType) else {
            throw APIError.invalidRequest
        }
    }
}

struct ScalarText: Decodable, Sendable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let integer = try? container.decode(Int.self) {
            value = String(integer)
        } else {
            let number = try container.decode(Double.self)
            value = number.rounded() == number ? String(Int(number)) : String(number)
        }
    }
}
