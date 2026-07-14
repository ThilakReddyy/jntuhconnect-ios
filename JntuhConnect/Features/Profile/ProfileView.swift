import SwiftUI

struct ProfileView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("appearance") private var appearance = "system"
    @State private var presentedURL: URL?
    @Bindable var recentStore: RecentSearchStore
    let onNavigate: (AppRoute) -> Void
    @State private var isTopGlassVisible = false
    @State private var isConfirmingLocalDataClear = false

    var body: some View {
        GeometryReader { geometry in
            Group {
                if usesRegularLayout(containerWidth: geometry.size.width) {
                    regularSettingsLayout
                } else {
                    compactSettingsList
                }
            }
            .overlay(alignment: .top) {
                StatusBarScrollGlass(height: geometry.safeAreaInsets.top)
                    .opacity(isTopGlassVisible ? 1 : 0)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle("Settings")
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        .sheet(item: $presentedURL) { InAppBrowser(url: $0).ignoresSafeArea() }
        .confirmationDialog(
            "Clear saved data?",
            isPresented: $isConfirmingLocalDataClear,
            titleVisibility: .visible
        ) {
            Button("Clear Saved Data", role: .destructive) {
                recentStore.clear()
                recentStore.clearDocuments()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes recent student summaries and document shortcuts stored on this device. Your appearance setting is kept.")
        }
    }

    private func usesRegularLayout(containerWidth: CGFloat) -> Bool {
        horizontalSizeClass == .regular
            && !dynamicTypeSize.isAccessibilitySize
            && containerWidth >= 760
    }

    private var compactSettingsList: some View {
        List {
            Section {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .listRowInsets(EdgeInsets(top: 56, leading: 20, bottom: 12, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            Section { compactAppIdentity }
            Section("Appearance") { compactAppearancePicker }
            Section("Data") {
                LabeledContent("Saved students", value: String(recentStore.students.count))
                LabeledContent("Document shortcuts", value: String(recentStore.documents.count))
                Button { onNavigate(.privacy) } label: {
                    Label("Privacy & Data", systemImage: "hand.raised")
                }
                .accessibilityIdentifier("profile.privacy")
                Button("Clear saved data", role: .destructive) {
                    isConfirmingLocalDataClear = true
                }
                .disabled(hasNoSavedData)
            }
            Section("Support") {
                Button { onNavigate(.channels) } label: {
                    Label("Channels", systemImage: "megaphone")
                }
                .accessibilityIdentifier("profile.channels")
                Button { onNavigate(.helpCenter) } label: {
                    Label("Help Center", systemImage: "questionmark.circle")
                }
                .accessibilityIdentifier("profile.help")
                Button { presentedURL = AppInformation.supportURL } label: {
                    Label("Report a Problem", systemImage: "exclamationmark.bubble")
                }
            }
            Section("About") {
                Button { presentedURL = AppInformation.websiteURL } label: {
                    Label("JNTUH Results website", systemImage: "safari")
                }
                ShareLink(item: AppInformation.websiteURL) {
                    Label("Share JNTUH Connect", systemImage: "square.and.arrow.up")
                }
                LabeledContent("Version", value: AppInformation.versionDescription)
            }
        }
        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y > 12 } action: { _, isVisible in
            updateTopGlass(isVisible)
        }
    }

    private var regularSettingsLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 20) {
                        SettingsDashboardCard { regularAppIdentity }
                        SettingsDashboardCard("Appearance") { regularAppearancePicker }
                        SettingsDashboardCard("About") { regularAboutContent }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                    VStack(spacing: 20) {
                        SettingsDashboardCard("Data") { regularDataContent }
                        SettingsDashboardCard("Support") { regularSupportContent }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .frame(maxWidth: 1040)
            .padding(.horizontal, 24)
            .padding(.top, 76)
            .padding(.bottom, 80)
            .frame(maxWidth: .infinity)
        }
        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y > 12 } action: { _, isVisible in
            updateTopGlass(isVisible)
        }
        .background(Color.appBackground)
    }

    private var compactAppIdentity: some View {
        HStack(spacing: 14) {
            Image("AppMark")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("JNTUH Connect").font(.title3.bold())
                Text("Results, resources, and academic tools")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var compactAppearancePicker: some View {
        Picker("Theme", selection: $appearance) {
            Text("System").tag("system")
            Text("Light").tag("light")
            Text("Dark").tag("dark")
        }
    }

    private var regularAppIdentity: some View {
        HStack(spacing: 14) {
            Image("AppMark")
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("JNTUH Connect").font(.title3.bold())
                Text("Results, resources, and academic tools")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private var regularAppearancePicker: some View {
        Picker("Theme", selection: $appearance) {
            Text("System").tag("system")
            Text("Light").tag("light")
            Text("Dark").tag("dark")
        }
        .pickerStyle(.segmented)
    }

    private var regularDataContent: some View {
        VStack(spacing: 14) {
            LabeledContent("Saved students", value: String(recentStore.students.count))
            Divider()
            LabeledContent("Document shortcuts", value: String(recentStore.documents.count))
            Divider()
            privacyButton
            Divider()
            Button(role: .destructive) {
                isConfirmingLocalDataClear = true
            } label: {
                SettingsActionLabel("Clear saved data", systemImage: "trash", showsChevron: false)
            }
            .buttonStyle(.plain)
            .disabled(hasNoSavedData)
        }
    }

    private var regularSupportContent: some View {
        VStack(spacing: 14) {
            channelsButton
            Divider()
            helpButton
            Divider()
            reportProblemButton
        }
    }

    private var regularAboutContent: some View {
        VStack(spacing: 14) {
            websiteButton
            Divider()
            ShareLink(item: AppInformation.websiteURL) {
                SettingsActionLabel("Share JNTUH Connect", systemImage: "square.and.arrow.up", showsChevron: false)
            }
            Divider()
            LabeledContent("Version", value: AppInformation.versionDescription)
        }
    }

    private var privacyButton: some View {
        Button { onNavigate(.privacy) } label: {
            SettingsActionLabel("Privacy & Data", systemImage: "hand.raised")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.privacy")
    }

    private var channelsButton: some View {
        Button { onNavigate(.channels) } label: {
            SettingsActionLabel("Channels", systemImage: "megaphone")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.channels")
    }

    private var helpButton: some View {
        Button { onNavigate(.helpCenter) } label: {
            SettingsActionLabel("Help Center", systemImage: "questionmark.circle")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.help")
    }

    private var reportProblemButton: some View {
        Button { presentedURL = AppInformation.supportURL } label: {
            SettingsActionLabel("Report a Problem", systemImage: "exclamationmark.bubble", showsChevron: false)
        }
        .buttonStyle(.plain)
    }

    private var websiteButton: some View {
        Button { presentedURL = AppInformation.websiteURL } label: {
            SettingsActionLabel("JNTUH Results website", systemImage: "safari", showsChevron: false)
        }
        .buttonStyle(.plain)
    }

    private var hasNoSavedData: Bool {
        recentStore.students.isEmpty && recentStore.documents.isEmpty
    }

    private func updateTopGlass(_ isVisible: Bool) {
        withAnimation(.easeOut(duration: 0.16)) {
            isTopGlassVisible = isVisible
        }
    }
}

private struct SettingsDashboardCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                Text(title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appOutline.opacity(0.42), lineWidth: 0.5)
        }
    }
}

private struct SettingsActionLabel: View {
    let title: String
    let systemImage: String
    let showsChevron: Bool

    init(_ title: String, systemImage: String, showsChevron: Bool = true) {
        self.title = title
        self.systemImage = systemImage
        self.showsChevron = showsChevron
    }

    var body: some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
}
