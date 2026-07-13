import Foundation

struct ContentDocument: Identifiable, Hashable, Sendable {
    let title: String
    let url: URL

    var id: String { title + url.absoluteString }
}

struct ContentEntry: Identifiable, Hashable, Sendable {
    let label: String
    let node: ContentNode

    var id: String { label }
}

indirect enum ContentNode: Decodable, Hashable, Sendable {
    case branch([ContentEntry])
    case documents([ContentDocument])

    var entries: [ContentEntry]? {
        guard case .branch(let entries) = self else { return nil }
        return entries
    }

    var documents: [ContentDocument]? {
        guard case .documents(let documents) = self else { return nil }
        return documents
    }

    func node(at path: [String]) -> ContentNode? {
        path.reduce(Optional(self)) { current, label in
            guard case .branch(let entries) = current else { return nil }
            return entries.first(where: { $0.label == label })?.node
        }
    }

    init(from decoder: Decoder) throws {
        if var array = try? decoder.unkeyedContainer() {
            var documents: [ContentDocument] = []
            while !array.isAtEnd {
                // `superDecoder()` advances the unkeyed container even when the
                // element cannot be decoded as a document. Decoding directly from
                // `array` would leave the index unchanged after a type mismatch and
                // retry the same malformed value forever.
                let elementDecoder = try array.superDecoder()
                guard let raw = try? RawContentDocument(from: elementDecoder) else { continue }
                if let document = raw.document { documents.append(document) }
            }
            self = .documents(documents)
            return
        }

        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let keys = container.allKeys
        let primitiveLeaf = !keys.isEmpty && keys.allSatisfy { key in
            (try? container.decode(String.self, forKey: key)) != nil
        }

        if primitiveLeaf {
            let documents = keys.compactMap { key -> ContentDocument? in
                guard let link = try? container.decode(String.self, forKey: key) else { return nil }
                return Self.makeDocument(title: key.stringValue, link: link)
            }
            self = .documents(documents)
        } else {
            let orderedKeys = keys.sorted { lhs, rhs in
                Self.branchSortKey(lhs.stringValue, rhs.stringValue)
            }
            self = .branch(try orderedKeys.map { key in
                ContentEntry(label: key.stringValue, node: try container.decode(ContentNode.self, forKey: key))
            })
        }
    }

    private static func branchSortKey(_ lhs: String, _ rhs: String) -> Bool {
        let lhsNumber = Int(lhs.filter(\.isNumber))
        let rhsNumber = Int(rhs.filter(\.isNumber))
        if let lhsNumber, let rhsNumber, lhsNumber != rhsNumber {
            return lhsNumber > rhsNumber
        }
        return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }

    private static func makeDocument(title: String, link: String) -> ContentDocument? {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: link.replacingOccurrences(of: " ", with: "%20")),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return ContentDocument(title: title, url: AppLinkPolicy.browserURL(url))
    }

    private struct RawContentDocument: Decodable {
        let title: String?
        let link: String?

        var document: ContentDocument? {
            guard let title, let link else { return nil }
            return ContentNode.makeDocument(title: title, link: link)
        }
    }
}

private struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
