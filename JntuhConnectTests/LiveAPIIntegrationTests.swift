import Foundation
import Testing
@testable import JntuhConnect

struct LiveAPIIntegrationTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_LIVE_API_TESTS"] == "1"))
    func configuredClientDecodesKnownAcademicResult() async throws {
        let key = try #require(Bundle.main.object(forInfoDictionaryKey: "JNTUHAPIKey") as? String)
        let client = APIClient(
            baseURL: URL(string: "https://jntuhresults.dhethi.com/api/")!,
            apiKey: key
        )

        let response = try await client.fetch(
            AcademicResultResponse.self,
            endpoint: .academicResult(rollNumber: "18E51A0479")
        )

        #expect(response.details?.rollNumber == "18E51A0479")
        #expect(!response.results.semesters.isEmpty)
    }
}
