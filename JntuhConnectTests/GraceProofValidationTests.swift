import Testing
@testable import JntuhConnect

struct GraceProofValidationTests {
    @Test func acceptsSupportedProofAndRejectsOversizedOrUnknownFiles() throws {
        try GraceProofFile.validate(size: 1024, mimeType: "application/pdf")
        #expect(throws: APIError.self) {
            try GraceProofFile.validate(size: 5 * 1024 * 1024 + 1, mimeType: "image/png")
        }
        #expect(throws: APIError.self) {
            try GraceProofFile.validate(size: 1024, mimeType: "text/plain")
        }
    }
}
