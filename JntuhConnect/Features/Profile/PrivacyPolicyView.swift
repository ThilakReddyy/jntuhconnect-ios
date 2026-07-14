import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Privacy & Data")
                            .font(.headline)
                        Text("Clear explanations and user-controlled access")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 4)
            }

            Section {
                PrivacyDetailRow(
                    symbol: "person.text.rectangle",
                    title: "Recent students",
                    detail: "Up to eight student summaries: name, hall ticket number, and branch. Full result responses are not saved by the app."
                )
                PrivacyDetailRow(
                    symbol: "clock",
                    title: "Recent documents",
                    detail: "Up to two document shortcuts expire after 24 hours."
                )
                PrivacyDetailRow(
                    symbol: "circle.lefthalf.filled",
                    title: "Appearance",
                    detail: "Your system, light, or dark theme preference."
                )
            } header: {
                Text("Stored on this device")
                    .accessibilityIdentifier("privacy.localData")
            }

            Section {
                PrivacyDetailRow(
                    symbol: "network",
                    title: "Result requests",
                    detail: "The hall ticket number you enter is sent over HTTPS to the JNTUH Connect backend so it can return the requested academic record."
                )
            } header: {
                Text("Sent when you use a feature")
                    .accessibilityIdentifier("privacy.sentData")
            }

            Section("What this app does not do") {
                Label("No advertising or cross-app tracking", systemImage: "eye.slash")
                Label("No third-party analytics SDK", systemImage: "chart.bar.xaxis")
                Label("No account or social sign-in", systemImage: "person.crop.circle.badge.xmark")
                Label("No document, photo, or video uploads", systemImage: "doc.badge.xmark")
                    .accessibilityIdentifier("privacy.noUploads")
            }

            Section("Your choices") {
                Text("You can choose not to submit a result request and can clear locally saved summaries and document shortcuts from Settings.")
                Text("For backend retention questions or a deletion request, use App Support. Never post a hall ticket number or academic document in a public issue; ask the maintainer to arrange a private channel.")
            }

            Section("Policy and support") {
                Link(destination: AppInformation.privacyPolicyURL) {
                    Label("Read the published privacy policy", systemImage: "doc.text")
                }
                Link(destination: AppInformation.supportURL) {
                    Label("App Support", systemImage: "questionmark.bubble")
                }
            }
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

private struct PrivacyDetailRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}
