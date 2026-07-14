import Foundation
import Testing
@testable import JntuhConnect

struct EndpointTests {
    @Test func academicResultBuildsEncodedQueryURL() throws {
        let endpoint = Endpoint.academicResult(rollNumber: "22J21A0501")
        let url = try endpoint.url(relativeTo: URL(string: "https://jntuhresults.dhethi.com/api/")!)
        #expect(url.absoluteString == "https://jntuhresults.dhethi.com/api/getAcademicResult?rollNumber=22J21A0501")
    }

    @Test func notificationsIncludesPaginationAndSupportedCategory() throws {
        let endpoint = Endpoint.notifications(page: 2, category: "results")
        let url = try endpoint.url(relativeTo: URL(string: "https://jntuhresults.dhethi.com/api/")!)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.contains(URLQueryItem(name: "page", value: "2")) == true)
        #expect(components?.queryItems?.contains(URLQueryItem(name: "category", value: "results")) == true)
    }

    @Test func notificationsRejectsInvalidPageAndUnsupportedCategory() {
        #expect(throws: APIError.self) {
            try Endpoint.notifications(page: 0, category: "all")
                .url(relativeTo: URL(string: "https://jntuhresults.dhethi.com/api/")!)
        }
        #expect(throws: APIError.self) {
            try Endpoint.notifications(page: 1, category: "exams")
                .url(relativeTo: URL(string: "https://jntuhresults.dhethi.com/api/")!)
        }
    }

    @Test func extendedResultEndpointsUseBackendContractNames() throws {
        let base = URL(string: "https://example.com/api/")!
        let contrast = try Endpoint.resultContrast(first: "18E51A0479", second: "18E51A0478").url(relativeTo: base)
        #expect(contrast.query?.contains("rollNumber1=18E51A0479") == true)
        #expect(contrast.query?.contains("rollNumber2=18E51A0478") == true)
        #expect(try Endpoint.classResults(rollNumber: "18E51A0479", type: "academicresult").url(relativeTo: base).absoluteString.contains("getClassResults"))
    }
}
