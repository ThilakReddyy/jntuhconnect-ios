import SwiftUI

struct ProfileView: View {
    @AppStorage("appearance") private var appearance = "system"
    @State private var presentedURL: URL?
    @Bindable var recentStore: RecentSearchStore
    let onNavigate: (AppRoute) -> Void
    @State private var isTopGlassVisible = false
    @State private var isConfirmingLocalDataClear = false

    var body: some View {
        GeometryReader { geometry in
            List {
                Section {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                        .listRowInsets(EdgeInsets(top: 56, leading: 20, bottom: 12, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                Section {
                    HStack(spacing: 14) {
                        Image("AppMark").resizable().scaledToFit().frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("JNTUH Connect").font(.title3.bold())
                            Text("Results, resources, and academic tools")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 6)
                }
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark")
                    }
                }
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
                    .disabled(recentStore.students.isEmpty && recentStore.documents.isEmpty)
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
                    Button {
                        presentedURL = AppInformation.supportURL
                    } label: {
                        Label("Report a Problem", systemImage: "exclamationmark.bubble")
                    }
                }
                Section {
                    Button { presentedURL = AppInformation.websiteURL } label: {
                        Label("JNTUH Results website", systemImage: "safari")
                    }
                    ShareLink(item: AppInformation.websiteURL) {
                        Label("Share JNTUH Connect", systemImage: "square.and.arrow.up")
                    }
                    LabeledContent("Version", value: AppInformation.versionDescription)
                } header: {
                    Text("About")
                }
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
}
