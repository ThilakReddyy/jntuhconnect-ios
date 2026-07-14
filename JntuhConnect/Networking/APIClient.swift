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

}
