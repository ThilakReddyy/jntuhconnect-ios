import Foundation

actor APIClient {
    static let live = APIClient(baseURL: URL(string: "https://jntuhresults.dhethi.com/api/")!)

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let apiKey: String?

    init(baseURL: URL, session: URLSession? = nil, apiKey: String? = nil) {
        self.baseURL = baseURL
        self.apiKey = apiKey ?? (Bundle.main.object(forInfoDictionaryKey: "JNTUHAPIKey") as? String)
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 60
            configuration.waitsForConnectivity = true
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.urlCache = nil
            configuration.httpAdditionalHeaders = [
                "Accept": "application/json",
                "User-Agent": "JNTUH-Connect-iOS/1.0"
            ]
            self.session = URLSession(configuration: configuration)
        }
        self.decoder = JSONDecoder()
    }

    func fetch<T: Decodable & Sendable>(_ type: T.Type, endpoint: Endpoint) async throws -> T {
        guard let apiKey, !apiKey.isEmpty else { throw APIError.missingAPIConfiguration }
        let url = try endpoint.url(relativeTo: baseURL)
        let request = APIRequestFactory.makeRequest(url: url, apiKey: apiKey)

        do {
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            let validatedData = try HTTPResponseInterpreter.validate(data: data, response: response)
            do {
                return try decoder.decode(T.self, from: validatedData)
            } catch {
                throw APIError.decoding
            }
        } catch let error as APIError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost: throw APIError.offline
            case .timedOut: throw APIError.timedOut
            case .cancelled: throw CancellationError()
            default: throw APIError.invalidResponse
            }
        }
    }

    func uploadGraceProof(data: Data, filename: String, mimeType: String, rollNumber: String) async throws -> GraceProofUploadResponse {
        guard let apiKey, !apiKey.isEmpty else { throw APIError.missingAPIConfiguration }
        try GraceProofFile.validate(size: data.count, mimeType: mimeType)

        let url = try Endpoint.graceProof(rollNumber: rollNumber).url(relativeTo: baseURL)
        let boundary = "JNTUHConnect-\(UUID().uuidString)"
        let safeFilename = filename.replacingOccurrences(of: "\"", with: "")
        var body = Data()
        func append(_ value: String) { body.append(Data(value.utf8)) }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeFilename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        append("\r\n--\(boundary)--\r\n")

        var request = APIRequestFactory.makeRequest(url: url, apiKey: apiKey)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (responseData, response) = try await session.data(for: request)
            let validatedData = try HTTPResponseInterpreter.validate(data: responseData, response: response)
            return try decoder.decode(GraceProofUploadResponse.self, from: validatedData)
        } catch let error as APIError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw APIError.offline
        } catch let error as URLError where error.code == .timedOut {
            throw APIError.timedOut
        } catch is DecodingError {
            throw APIError.decoding
        }
    }

}
