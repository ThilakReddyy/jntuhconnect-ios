import Foundation
import Observation

@MainActor
@Observable
final class UpdatesStore {
    private(set) var updates: [LatestNotification] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var category = "all" {
        didSet { if category != oldValue { updates = [] } }
    }
    private let client: APIClient
    private var requestID: UUID?

    init(client: APIClient = .live) { self.client = client }

    func load() async {
        let id = UUID()
        requestID = id
        isLoading = true
        errorMessage = nil
        do {
            let response = try await client.fetch(
                [LatestNotification].self,
                endpoint: .notifications(page: 1, category: category)
            )
            guard requestID == id else { return }
            updates = response
            isLoading = false
        } catch is CancellationError {
            if requestID == id { isLoading = false }
        } catch {
            guard requestID == id else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unable to load updates."
            isLoading = false
        }
    }
}
