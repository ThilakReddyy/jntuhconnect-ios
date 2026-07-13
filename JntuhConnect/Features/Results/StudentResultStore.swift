import Foundation
import Observation

enum ResultLoadState: Sendable {
    case idle
    case loading
    case pending(String)
    case loaded(AcademicResultResponse)
    case failed(String)
}

@MainActor
@Observable
final class StudentResultStore {
    private(set) var state: ResultLoadState = .idle
    private let client: APIClient
    private var requestID: UUID?

    init(client: APIClient = .live) {
        self.client = client
    }

    func load(rollNumber: RollNumber) async {
        guard rollNumber.isValid else {
            state = .failed("Enter a valid 10-character hall ticket number.")
            return
        }
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
            let response = try await client.fetch(
                AcademicResultResponse.self,
                endpoint: .academicResult(rollNumber: rollNumber.rawValue)
            )
            guard requestID == id else { return }
            state = .loaded(response)
        } catch APIError.pending(let message) {
            guard requestID == id else { return }
            state = .pending(message)
        } catch is CancellationError {
            return
        } catch {
            guard requestID == id else { return }
            state = .failed((error as? LocalizedError)?.errorDescription ?? "Something went wrong.")
        }
    }
}
