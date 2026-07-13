import SwiftUI

struct ResultEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let flow: ResultFlow
    let onSubmit: (ResultRequest) -> Void

    @State private var primary = ""
    @State private var secondary = ""
    @State private var validationMessage: String?
    @State private var classMode: ClassResultMode = .academic
    @FocusState private var focusedField: Field?

    private enum Field { case primary, secondary }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 16 : 24) {
                    header
                    if flow == .classResults {
                        Picker("Result type", selection: $classMode) {
                            ForEach(ClassResultMode.allCases) { mode in Text(mode.title).tag(mode) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: classMode) { focusedField = nil }
                    }
                    fields

                    if let validationMessage {
                        Label(validationMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(action: submit) {
                        Label(flow.title == "Academic result" ? "View result" : actionTitle, systemImage: "arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .accessibilityIdentifier("result.submit")
                    .foregroundStyle(Color.appBackground)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.immediately)
            .background {
                Color.appBackground
                    .onTapGesture { focusedField = nil }
            }
            .navigationTitle(flow.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        focusedField = nil
                        dismiss()
                    }
                        .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents(presentationDetents)
        .presentationDragIndicator(.visible)
        .onAppear { focusedField = .primary }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                Text(flow.needsSecondRollNumber
                     ? "Enter two hall ticket numbers."
                     : "Enter a 10-character hall ticket number.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: flow.symbol)
                        .font(.title2.weight(.semibold))
                        .frame(width: 48, height: 48)
                        .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityHidden(true)

                    Text(flow.prompt)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var presentationDetents: Set<PresentationDetent> {
        if dynamicTypeSize.isAccessibilitySize || flow.needsSecondRollNumber { return [.large] }
        return [.medium, .large]
    }

    private var fields: some View {
        VStack(spacing: 14) {
            rollField(title: flow.needsSecondRollNumber ? "First hall ticket number" : "Hall ticket number", text: $primary, field: .primary)
            if flow.needsSecondRollNumber {
                rollField(title: "Second hall ticket number", text: $secondary, field: .secondary)
            }
        }
    }

    private func rollField(title: String, text: Binding<String>, field: Field) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.text.rectangle")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(title, text: text)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(field == .primary && flow.needsSecondRollNumber ? .next : .go)
                .focused($focusedField, equals: field)
                .accessibilityIdentifier(field == .primary ? "result.primaryRoll" : "result.secondaryRoll")
                .onSubmit {
                    if field == .primary && flow.needsSecondRollNumber { focusedField = .secondary }
                    else { submit() }
                }
                .onChange(of: text.wrappedValue) { _, value in
                    let normalized = String(value.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(10))
                    if normalized != value { text.wrappedValue = normalized }
                    validationMessage = nil
                }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 54)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appOutline.opacity(0.55), lineWidth: 0.75)
        }
    }

    private var actionTitle: String {
        switch flow {
        case .contrast: "Compare results"
        case .classResults: "Load class"
        case .graceMarks: "Check eligibility"
        default: "View report"
        }
    }

    private func submit() {
        focusedField = nil
        do {
            let request = try flow.makeRequest(primary: primary, secondary: secondary, classMode: classMode)
            onSubmit(request)
        } catch {
            validationMessage = (error as? LocalizedError)?.errorDescription ?? "Check the entered hall ticket number."
        }
    }
}
