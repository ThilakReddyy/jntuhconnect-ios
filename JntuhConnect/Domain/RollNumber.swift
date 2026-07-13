import Foundation

struct RollNumber: Hashable, Identifiable, Sendable {
    let rawValue: String
    var id: String { rawValue }

    init(_ value: String) {
        rawValue = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var isValid: Bool {
        rawValue.count == 10 && rawValue.unicodeScalars.allSatisfy(CharacterSet.alphanumerics.contains)
    }
}
