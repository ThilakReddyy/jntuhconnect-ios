import SwiftUI

struct ExploreView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Bindable var recentStore: RecentSearchStore
    let onNavigate: (AppRoute) -> Void
    @State private var selectedFlow: ResultFlow?
    @State private var isTopGlassVisible = false

    private let sections: [(String, [Tool])] = [
        ("Student results", [
            Tool("Academic result", "CGPA and consolidated marks", "graduationcap", .secondary, flow: .academic),
            Tool("All results", "Every attempt by semester", "books.vertical", .secondary, flow: .allResults),
            Tool("Backlog report", "Subjects left to clear", "exclamationmark.circle", .red, flow: .backlogs),
            Tool("Credits checker", "Obtained versus required", "chart.bar", .appGold, flow: .credits)
        ]),
        ("Analysis", [
            Tool("Result contrast", "Compare two students", "arrow.left.arrow.right", .secondary, flow: .contrast),
            Tool("Class result", "Rank an entire class", "person.3", .secondary, flow: .classResults)
        ]),
        ("Resources", [
            Tool("Updates", "Latest JNTUH notifications", "bell", .secondary, destination: .updates),
            Tool("Calendars", "Browse official academic calendars", "calendar", .secondary, destination: .resource(.calendars)),
            Tool("Syllabus", "Degree, regulation and branch PDFs", "book.closed", .secondary, destination: .resource(.syllabus)),
            Tool("Channels", "Telegram, WhatsApp and Instagram", "megaphone", .secondary, destination: .channels),
            Tool("Help center", "Results, credits and support answers", "questionmark.circle", .secondary, destination: .help)
        ])
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    Text("Explore")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)

                    ForEach(sections, id: \.0) { section, tools in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section).font(.title3.bold()).accessibilityAddTraits(.isHeader)
                            LazyVGrid(columns: columns(containerWidth: geometry.size.width), spacing: 12) {
                                ForEach(tools) { tool in
                                    toolNavigation(tool)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 1180)
                .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 16)
                .padding(.top, 76)
                .padding(.bottom, 106)
                .frame(maxWidth: .infinity)
            }
            .onScrollGeometryChange(for: Bool.self) { scrollGeometry in
                scrollGeometry.contentOffset.y > 12
            } action: { _, isVisible in
                withAnimation(.easeOut(duration: 0.16)) {
                    isTopGlassVisible = isVisible
                }
            }
            .overlay(alignment: .top) {
                StatusBarScrollGlass(height: geometry.safeAreaInsets.top)
                    .opacity(isTopGlassVisible ? 1 : 0)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.appBackground)
        .navigationTitle("Explore")
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedFlow) { flow in
            ResultEntrySheet(flow: flow) { request in
                selectedFlow = nil
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    if let section = StudentResultSection(flow: request.flow) {
                        onNavigate(.student(request.primary, section))
                    } else {
                        onNavigate(.extended(request))
                    }
                }
            }
        }
    }

    private func columns(containerWidth: CGFloat) -> [GridItem] {
        guard horizontalSizeClass == .regular, !dynamicTypeSize.isAccessibilitySize else {
            return [GridItem(.flexible())]
        }

        let count = containerWidth >= 960 ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    @ViewBuilder
    private func toolNavigation(_ tool: Tool) -> some View {
        if let flow = tool.flow {
            Button { selectedFlow = flow } label: { ToolRow(tool: tool) }
                .buttonStyle(.plain)
                .accessibilityIdentifier("explore.\(flow.rawValue)")
        } else if let destination = tool.destination {
            switch destination {
            case .updates:
                NavigationLink { UpdatesView() } label: { ToolRow(tool: tool) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("explore.updates")
            case .resource(let kind):
                Button { onNavigate(.resource(kind)) } label: { ToolRow(tool: tool) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("explore.resource.\(kind.rawValue)")
            case .channels:
                Button { onNavigate(.channels) } label: { ToolRow(tool: tool) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("explore.channels")
            case .help:
                Button { onNavigate(.helpCenter) } label: { ToolRow(tool: tool) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("explore.help")
            }
        } else {
            NavigationLink { FeaturePlaceholderView(tool: tool) } label: { ToolRow(tool: tool) }
                .buttonStyle(.plain)
        }
    }
}

private enum ToolDestination: Equatable {
    case updates
    case resource(ResourceKind)
    case channels
    case help
}

private struct Tool: Identifiable {
    var id: String { title }
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: ToolDestination?
    let flow: ResultFlow?

    init(_ title: String, _ subtitle: String, _ icon: String, _ color: Color, destination: ToolDestination? = nil, flow: ResultFlow? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.destination = destination
        self.flow = flow
    }
}

private struct ToolRow: View {
    let tool: Tool
    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                Image(systemName: tool.icon).font(.title3).foregroundStyle(tool.color).frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.title).font(.headline).foregroundStyle(.primary)
                    Text(tool.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct FeaturePlaceholderView: View {
    let tool: Tool
    var body: some View {
        ContentUnavailableView(tool.title, systemImage: tool.icon, description: Text("This resource still needs its dedicated native iOS browser."))
            .navigationTitle(tool.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}
