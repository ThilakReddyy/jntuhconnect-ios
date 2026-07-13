import SwiftUI

struct UpdatesView: View {
    @State private var store = UpdatesStore()
    @State private var presentedURL: URL?
    private let categories = ["all", "results"]

    var body: some View {
        List {
            Picker("Category", selection: $store.category) {
                ForEach(categories, id: \.self) { Text($0.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            if store.isLoading && store.updates.isEmpty {
                AppLoadingView(
                    "Loading updates",
                    message: "Checking the latest JNTUH notifications.",
                    compact: true
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            } else if let message = store.errorMessage, store.updates.isEmpty {
                ContentUnavailableView {
                    Label("Updates unavailable", systemImage: "wifi.exclamationmark")
                } description: { Text(message) } actions: {
                    Button("Try again") { Task { await store.load() } }
                }.listRowBackground(Color.clear)
            } else {
                ForEach(store.updates) { update in
                    Button { presentedURL = update.link } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(update.title).font(.headline).foregroundStyle(.primary)
                            HStack {
                                Label(update.category, systemImage: "tag")
                                Spacer(); Text(update.releaseDate)
                            }.font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the update on the JNTUH website")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Updates")
        .refreshable { await store.load() }
        .task(id: store.category) { await store.load() }
        .sheet(item: $presentedURL) { InAppBrowser(url: $0).ignoresSafeArea() }
    }
}
