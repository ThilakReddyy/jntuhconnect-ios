import Foundation

struct HTTPResponseInterpreter {
    static func validate(data: Data, response: URLResponse) throws -> Data {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 202 {
            throw APIError.pending(message(from: data) ?? "Your result is being prepared. Please try again shortly.")
        }

        if http.statusCode == 429 {
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw APIError.rateLimited(retryAfter: retryAfter)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode, message(from: data))
        }
        return data
    }

    static func message(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
        return message(from: json)
    }

    private static func message(from value: Any) -> String? {
        if let text = value as? String { return text }
        if let object = value as? [String: Any] {
            if let text = object["message"] as? String { return text }
            if let text = object["error"] as? String { return text }
            if let detail = object["detail"], let text = message(from: detail) { return text }
        }
        if let array = value as? [Any] {
            let messages = array.compactMap(message(from:))
            return messages.isEmpty ? nil : messages.joined(separator: "\n")
        }
        return nil
    }
}
