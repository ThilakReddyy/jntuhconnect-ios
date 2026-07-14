import Foundation

enum Endpoint: Sendable {
    case academicResult(rollNumber: String)
    case allResults(rollNumber: String)
    case backlogs(rollNumber: String)
    case credits(rollNumber: String)
    case resultContrast(first: String, second: String)
    case classResults(rollNumber: String, type: String)
    case notifications(page: Int, category: String)
    case calendars
    case syllabus

    private var path: String {
        switch self {
        case .academicResult: "getAcademicResult"
        case .allResults: "getAllResult"
        case .backlogs: "getBacklogs"
        case .credits: "getCreditsChecker"
        case .resultContrast: "getResultContrast"
        case .classResults: "getClassResults"
        case .notifications: "notifications"
        case .calendars: "calendars"
        case .syllabus: "syllabus"
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case .academicResult(let rollNumber), .allResults(let rollNumber),
             .backlogs(let rollNumber), .credits(let rollNumber):
            [URLQueryItem(name: "rollNumber", value: rollNumber)]
        case .resultContrast(let first, let second):
            [
                URLQueryItem(name: "rollNumber1", value: first),
                URLQueryItem(name: "rollNumber2", value: second)
            ]
        case .classResults(let rollNumber, let type):
            [URLQueryItem(name: "rollNumber", value: rollNumber), URLQueryItem(name: "type", value: type)]
        case .notifications(let page, let category):
            [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "category", value: category)]
        case .calendars, .syllabus:
            []
        }
    }

    func url(relativeTo baseURL: URL) throws -> URL {
        if case .notifications(let page, let category) = self {
            guard page >= 1, ["all", "results"].contains(category) else {
                throw APIError.invalidRequest
            }
        }
        guard var components = URLComponents(
            url: baseURL.appending(path: path, directoryHint: .notDirectory),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidURL }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }
}

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidRequest
    case missingAPIConfiguration
    case invalidResponse
    case httpStatus(Int, String?)
    case decoding
    case pending(String)
    case rateLimited(retryAfter: TimeInterval?)
    case offline
    case timedOut

    var errorDescription: String? {
        switch self {
        case .invalidURL: "The request URL is invalid."
        case .invalidRequest: "The request contains unsupported values."
        case .missingAPIConfiguration: "This build is missing its public API access configuration."
        case .invalidResponse: "The server returned an invalid response."
        case .httpStatus(_, let message): message ?? "JNTUH Results is unavailable right now."
        case .decoding: "The result format has changed. Please update the app."
        case .pending(let message): message
        case .rateLimited(let retryAfter):
            if let retryAfter { "Too many requests. Try again in \(Int(retryAfter)) seconds." }
            else { "Too many requests. Please wait and try again." }
        case .offline: "You appear to be offline."
        case .timedOut: "The request took too long. Please try again."
        }
    }
}
