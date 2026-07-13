import Foundation
import Testing
@testable import JntuhConnect

struct HTTPResponseInterpreterTests {
    @Test func queuedResponseBecomesPendingState() throws {
        let data = Data(#"{"status":"success","message":"Your roll number has been queued."}"#.utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 202,
            httpVersion: nil,
            headerFields: nil
        )!

        do {
            _ = try HTTPResponseInterpreter.validate(data: data, response: response)
            Issue.record("Expected pending error")
        } catch APIError.pending(let message) {
            #expect(message == "Your roll number has been queued.")
        }
    }

    @Test func nestedFastAPIErrorMessageIsPreserved() throws {
        let data = Data(#"{"detail":{"status":"failure","message":"Invalid hall ticket number"}}"#.utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 422,
            httpVersion: nil,
            headerFields: nil
        )!

        do {
            _ = try HTTPResponseInterpreter.validate(data: data, response: response)
            Issue.record("Expected HTTP error")
        } catch APIError.httpStatus(let code, let message) {
            #expect(code == 422)
            #expect(message == "Invalid hall ticket number")
        }
    }

    @Test func rateLimitIncludesRetryAfter() throws {
        let data = Data(#"{"message":"Too many requests"}"#.utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: ["Retry-After": "12"]
        )!

        do {
            _ = try HTTPResponseInterpreter.validate(data: data, response: response)
            Issue.record("Expected rate-limit error")
        } catch APIError.rateLimited(let retryAfter) {
            #expect(retryAfter == 12)
        }
    }
}
