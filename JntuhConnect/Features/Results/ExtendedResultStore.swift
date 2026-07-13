import Foundation
import Observation

enum ExtendedResultPayload: Sendable {
    case allResults(AllResultsResponse)
    case backlogs(BacklogResponse)
    case credits(CreditsResponse)
    case contrast(ResultContrastResponse)
    case classResults([ClassResultStudent])
    case classBacklogs([ClassBacklogStudent])
    case grace(GraceEligibilityResponse)
}

enum ExtendedResultState: Sendable {
    case idle
    case loading
    case loaded(ExtendedResultPayload)
    case pending(String)
    case unavailable(String)
    case failed(String)
}

enum ProofUploadState: Sendable {
    case idle
    case uploading
    case succeeded(GraceProofUploadResponse)
    case failed(String)
}

@MainActor @Observable
final class ExtendedResultStore {
    var state: ExtendedResultState = .idle
    var proofUploadState: ProofUploadState = .idle
    private let client: APIClient
    private var requestID: UUID?

    init(client: APIClient = .live) { self.client = client }

    func fail(_ message: String) {
        state = .failed(message)
    }

    func load(_ request: ResultRequest) async {
        let id = UUID()
        requestID = id
        state = .loading

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-test-hold-loading") {
            try? await Task.sleep(for: .seconds(4))
            guard requestID == id else { return }
        }
        #endif

        do {
            let payload: ExtendedResultPayload
            switch request.flow {
            case .allResults:
                payload = .allResults(try await client.fetch(AllResultsResponse.self, endpoint: .allResults(rollNumber: request.primary.rawValue)))
            case .backlogs:
                payload = .backlogs(try await client.fetch(BacklogResponse.self, endpoint: .backlogs(rollNumber: request.primary.rawValue)))
            case .credits:
                let response = try await client.fetch(CreditsResponse.self, endpoint: .credits(rollNumber: request.primary.rawValue))
                if response.status?.lowercased() == "failure" || response.results == nil {
                    guard requestID == id else { return }
                    state = .unavailable(response.message ?? "Credits are not available for this student.")
                    return
                }
                payload = .credits(response)
            case .contrast:
                guard let secondary = request.secondary else { throw APIError.invalidRequest }
                payload = .contrast(try await client.fetch(ResultContrastResponse.self, endpoint: .resultContrast(first: request.primary.rawValue, second: secondary.rawValue)))
            case .classResults:
                if request.classMode == .backlogs {
                    payload = .classBacklogs(try await client.fetch([ClassBacklogStudent].self, endpoint: .classResults(rollNumber: request.primary.rawValue, type: ClassResultMode.backlogs.rawValue)))
                } else {
                    payload = .classResults(try await client.fetch([ClassResultStudent].self, endpoint: .classResults(rollNumber: request.primary.rawValue, type: ClassResultMode.academic.rawValue)))
                }
            case .graceMarks:
                payload = .grace(try await client.fetch(GraceEligibilityResponse.self, endpoint: .graceEligibility(rollNumber: request.primary.rawValue)))
            case .academic:
                throw APIError.invalidRequest
            }

            guard requestID == id else { return }
            state = .loaded(payload)
        } catch APIError.pending(let message) {
            guard requestID == id else { return }
            state = .pending(message)
        } catch APIError.httpStatus(let status, let message) where status == 404 || status == 406 {
            guard requestID == id else { return }
            state = .unavailable(message ?? "This report is not available for the entered student.")
        } catch is CancellationError {
            return
        } catch {
            guard requestID == id else { return }
            state = .failed((error as? LocalizedError)?.errorDescription ?? "Unable to load this report.")
        }
    }

    func uploadProof(from url: URL, rollNumber: RollNumber) async {
        proofUploadState = .uploading
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let size = values.fileSize ?? 0
            let ext = url.pathExtension.lowercased()
            let mimeType: String
            switch ext {
            case "pdf": mimeType = "application/pdf"
            case "png": mimeType = "image/png"
            case "jpg", "jpeg": mimeType = "image/jpeg"
            default: throw APIError.invalidRequest
            }
            try GraceProofFile.validate(size: size, mimeType: mimeType)
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let response = try await client.uploadGraceProof(
                data: data,
                filename: url.lastPathComponent,
                mimeType: mimeType,
                rollNumber: rollNumber.rawValue
            )
            proofUploadState = .succeeded(response)
        } catch {
            proofUploadState = .failed((error as? LocalizedError)?.errorDescription ?? "Unable to upload this proof.")
        }
    }
}
