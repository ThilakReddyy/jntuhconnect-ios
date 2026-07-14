import SwiftUI
import Observation

// MARK: - Live syllabus and calendar browser

enum ResourceKind: String, Hashable, Sendable {
    case calendars
    case syllabus

    var title: String {
        switch self {
        case .calendars: "Academic Calendars"
        case .syllabus: "Syllabus"
        }
    }

    var shortTitle: String {
        switch self {
        case .calendars: "Calendars"
        case .syllabus: "Syllabus"
        }
    }

    var prompt: String {
        switch self {
        case .calendars: "Select an academic year to find the calendar for your course and study year."
        case .syllabus: "Choose your degree, regulation and branch to find the official syllabus."
        }
    }

    var symbol: String {
        switch self {
        case .calendars: "calendar.badge.clock"
        case .syllabus: "books.vertical"
        }
    }

    var endpoint: Endpoint {
        switch self {
        case .calendars: .calendars
        case .syllabus: .syllabus
        }
    }
}

@MainActor
@Observable
final class ContentTreeStore {
    private(set) var root: ContentNode?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let client: APIClient
    private var requestID: UUID?

    init(client: APIClient = .live) {
        self.client = client
    }

    func load(_ kind: ResourceKind) async {
        let id = UUID()
        requestID = id
        isLoading = true
        errorMessage = nil
        do {
            let response = try await client.fetch(ContentNode.self, endpoint: kind.endpoint)
            guard requestID == id else { return }
            root = response
            isLoading = false
        } catch is CancellationError {
            if requestID == id { isLoading = false }
        } catch {
            guard requestID == id else { return }
            root = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unable to load this resource."
            isLoading = false
        }
    }
}

struct ContentTreeView: View {
    let kind: ResourceKind
    @Bindable var recentStore: RecentSearchStore
    @State private var store = ContentTreeStore()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ResourceHero(
                    symbol: kind.symbol,
                    eyebrow: "OFFICIAL JNTUH RESOURCE",
                    title: kind.shortTitle,
                    description: kind.prompt
                )

                if store.isLoading {
                    ContentLoadingView()
                } else if let message = store.errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't load \(kind.shortTitle.lowercased())", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try again") { Task { await store.load(kind) } }
                            .buttonStyle(.borderedProminent)
                            .tint(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                } else if let root = store.root {
                    ContentNodeLevel(kind: kind, title: "Browse", node: root, recentStore: recentStore)
                } else {
                    ResourceEmptyView(symbol: kind.symbol, title: "Nothing here yet", message: "Check back later for updates.")
                }
            }
            .frame(maxWidth: 1180)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 36)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .task(id: kind) { await store.load(kind) }
    }
}

private struct ContentNodeLevel: View {
    let kind: ResourceKind
    let title: String
    let node: ContentNode
    @Bindable var recentStore: RecentSearchStore
    @State private var presentedURL: URL?

    private let columns = [GridItem(.adaptive(minimum: 280), spacing: 12, alignment: .top)]

    var body: some View {
        Group {
            switch node {
            case .branch(let entries):
                if entries.isEmpty {
                    ResourceEmptyView(symbol: kind.symbol, title: "Nothing here yet", message: "This section does not contain any resources.")
                } else {
                    SectionCaption(title: title, detail: "\(entries.count) option\(entries.count == 1 ? "" : "s")")
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        ForEach(entries) { entry in
                            NavigationLink {
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 14) {
                                        ContentNodeLevel(
                                            kind: kind,
                                            title: entry.label,
                                            node: entry.node,
                                            recentStore: recentStore
                                        )
                                    }
                                    .frame(maxWidth: 1180)
                                    .padding(16)
                                    .padding(.bottom, 28)
                                    .frame(maxWidth: .infinity)
                                }
                                .background(Color.appBackground)
                                .navigationTitle(entry.label)
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbarVisibility(.hidden, for: .tabBar)
                            } label: {
                                ContentFolderRow(entry: entry, symbol: kind.symbol)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens this section")
                        }
                    }
                }
            case .documents(let documents):
                if documents.isEmpty {
                    ResourceEmptyView(symbol: kind.symbol, title: "No documents", message: "There are no documents in this section yet.")
                } else {
                    SectionCaption(title: title, detail: "\(documents.count) document\(documents.count == 1 ? "" : "s")")
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        ForEach(documents) { document in
                            Button {
                                recentStore.save(document, source: kind.shortTitle)
                                presentedURL = document.url
                            } label: {
                                ContentDocumentRow(document: document)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the document in a secure browser")
                        }
                    }
                }
            }
        }
        .sheet(item: $presentedURL) { url in
            InAppBrowser(url: url).ignoresSafeArea()
        }
    }
}

private struct ContentLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.13)).frame(width: 46, height: 46)
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.14)).frame(height: 13)
                        RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.10)).frame(width: 120, height: 10)
                    }
                    Spacer()
                }
                .padding(15)
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading resources")
    }
}

private struct ContentFolderRow: View {
    let entry: ContentEntry
    let symbol: String

    private var countLabel: String {
        switch entry.node {
        case .branch(let entries): "\(entries.count) folder\(entries.count == 1 ? "" : "s")"
        case .documents(let documents): "\(documents.count) document\(documents.count == 1 ? "" : "s")"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.headline.weight(.semibold))
                .frame(width: 46, height: 46)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.label).font(.headline).foregroundStyle(.primary)
                Text(countLabel).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(15)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.appOutline.opacity(0.42), lineWidth: 0.5) }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct ContentDocumentRow: View {
    let document: ContentDocument

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.richtext")
                .font(.headline.weight(.semibold))
                .frame(width: 46, height: 46)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title).font(.headline).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                Text(document.url.host() ?? "Official document").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(15)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.appOutline.opacity(0.42), lineWidth: 0.5) }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Channels and help

struct ChannelsView: View {
    @State private var presentedURL: URL?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ResourceHero(
                    symbol: "dot.radiowaves.left.and.right",
                    eyebrow: "STAY IN THE LOOP",
                    title: "JNTUH Connect channels",
                    description: "Get result alerts, university notices and product updates where you already spend time."
                )

                SectionCaption(title: "JNTUH Connect communities", detail: "Choose where to follow updates")
                ForEach(Array(ResourceContent.channels.prefix(2))) { channel in
                    Button { presentedURL = channel.url } label: {
                        ChannelRow(channel: channel)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens \(channel.platform) in a secure browser")
                }

                SectionCaption(title: "From the creator", detail: "Product progress and tech content")
                ForEach(Array(ResourceContent.channels.dropFirst(2))) { channel in
                    Button { presentedURL = channel.url } label: {
                        ChannelRow(channel: channel)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens \(channel.platform) in a secure browser")
                }

                Text("Channels are hosted by their respective platforms. Notification and privacy settings are controlled there.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground)
        .navigationTitle("Channels")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .sheet(item: $presentedURL) { InAppBrowser(url: $0).ignoresSafeArea() }
    }
}

private struct ChannelRow: View {
    let channel: ChannelLink

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: channel.symbol)
                .font(.title3.weight(.semibold))
                .frame(width: 48, height: 48)
                .background(Color.primary.opacity(0.065), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(channel.name).font(.headline).foregroundStyle(.primary)
                    Text(channel.platform.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(0.5)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.07), in: Capsule())
                }
                Text(channel.description).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(15)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(Color.appOutline.opacity(0.42), lineWidth: 0.5) }
        .contentShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

struct HelpCenterView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expandedFAQ: FAQItem.ID?
    @State private var presentedURL: URL?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ResourceHero(
                    symbol: "questionmark.bubble",
                    eyebrow: "HELP CENTER",
                    title: "Answers without the runaround",
                    description: "Understand result data, queued searches, and credits before reaching out."
                )

                SectionCaption(title: "Frequently asked questions", detail: "Tap a question to read the answer")
                ForEach(ResourceContent.faqs) { faq in
                    FAQCard(faq: faq, isExpanded: expandedFAQ == faq.id) {
                        let next = expandedFAQ == faq.id ? nil : faq.id
                        if reduceMotion { expandedFAQ = next }
                        else { withAnimation(.snappy) { expandedFAQ = next } }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Still need help?", systemImage: "paperplane")
                        .font(.headline)
                    Text("Talk to us on Telegram for product support and help finding the right result tool.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Open support channel", systemImage: "arrow.up.right") {
                        presentedURL = ResourceContent.channels[0].url
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.appOutline.opacity(0.42), lineWidth: 0.5) }
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground)
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .sheet(item: $presentedURL) { InAppBrowser(url: $0).ignoresSafeArea() }
    }
}

private struct FAQCard: View {
    let faq: FAQItem
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: isExpanded ? 12 : 0) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(faq.question)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                if isExpanded {
                    Divider()
                    Text(faq.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity)
                }
            }
            .padding(16)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.appOutline.opacity(0.42), lineWidth: 0.5) }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(faq.question)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Collapses this answer" : "Shows the answer")
    }
}

private struct ResourceHero: View {
    let symbol: String
    let eyebrow: String
    let title: String
    let description: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: symbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.62))
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.heroGradient(for: colorScheme), in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(.white.opacity(colorScheme == .dark ? 0.13 : 0.06), lineWidth: 0.75)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SectionCaption: View {
    let title: String
    let detail: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .lastTextBaseline) {
                Text(title).font(.title3.bold()).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 12)
                Text(detail).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title3.bold()).accessibilityAddTraits(.isHeader)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 3)
    }
}

private struct ResourceEmptyView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(message))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
    }
}


struct ChannelLink: Identifiable, Hashable, Sendable {
    let name: String
    let description: String
    let url: URL
    let platform: String
    let symbol: String
    var id: URL { url }
}

struct FAQItem: Identifiable, Hashable, Sendable {
    let question: String
    let answer: String
    var id: String { question }
}

private enum ResourceContent {
    static let channels: [ChannelLink] = [
        ChannelLink(name: "JNTUH Connect", description: "Instant alerts when JNTUH exam results are published.", url: URL(string: "https://t.me/jntuhvercel")!, platform: "Telegram", symbol: "paperplane.fill"),
        ChannelLink(name: "WhatsApp group", description: "Quick result alerts and important university updates.", url: URL(string: "https://chat.whatsapp.com/EBIhYt8Jt9rJFNrgUsbmiR")!, platform: "WhatsApp", symbol: "message.fill"),
        ChannelLink(name: "@__thilak_reddy__", description: "Creator updates, product progress and technology content.", url: URL(string: "https://www.instagram.com/__thilak_reddy__/")!, platform: "Instagram", symbol: "camera.fill")
    ]

    static let faqs: [FAQItem] = [
        FAQItem(question: "How do I check my complete result?", answer: "Enter your 10-character hall ticket number on Home. The Student Result screen includes All Results, Academic, Backlogs and Credits in one place; switch sections without searching again."),
        FAQItem(question: "Why does my roll number say queued?", answer: "When a result is not cached, the server starts fetching it in the background. Wait a few moments and try the same hall ticket number again."),
        FAQItem(question: "How is CGPA calculated?", answer: "The best available grade for each subject is used. CGPA is credit-weighted and is shown only when there are no active backlogs."),
        FAQItem(question: "What does Credits Checker show?", answer: "It compares earned credits with the regulation requirement, including year-wise and semester-wise progress. It is currently intended for B.Tech students."),
        FAQItem(question: "Can I verify marks on the JNTUH website?", answer: "Yes. All Results includes the official result link for each declared exam whenever the backend provides one.")
    ]
}
