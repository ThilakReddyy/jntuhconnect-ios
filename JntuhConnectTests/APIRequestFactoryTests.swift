import Foundation
import Testing
@testable import JntuhConnect

struct APIRequestFactoryTests {
    @Test func configuredPublicAccessKeyIsAddedToBackendRequest() throws {
        let request = APIRequestFactory.makeRequest(
            url: URL(string: "https://jntuhresults.dhethi.com/api/health")!,
            apiKey: "configured-at-build-time"
        )
        #expect(request.value(forHTTPHeaderField: "X-Api-Key") == "configured-at-build-time")
    }

    @Test func emptyAccessKeyDoesNotCreateHeader() throws {
        let request = APIRequestFactory.makeRequest(
            url: URL(string: "https://jntuhresults.dhethi.com/api/health")!,
            apiKey: ""
        )
        #expect(request.value(forHTTPHeaderField: "X-Api-Key") == nil)
    }
}
