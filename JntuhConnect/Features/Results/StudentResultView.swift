import SwiftUI

struct StudentResultView: View {
    let rollNumber: RollNumber
    @Bindable var recentStore: RecentSearchStore

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedSection: StudentResultSection
    @State private var academicStore = StudentResultStore()
    @State private var allResultsStore = ExtendedResultStore()
    @State private var backlogStore = ExtendedResultStore()
    @State private var creditsStore = ExtendedResultStore()
    @State private var loadedSections: Set<StudentResultSection> = []
    @State private var containerWidth: CGFloat = 0

    init(
        rollNumber: RollNumber,
        recentStore: RecentSearchStore,
        initialSection: StudentResultSection = .academic
    ) {
        self.rollNumber = rollNumber
        self.recentStore = recentStore
        _selectedSection = State(initialValue: initialSection)
    }

    var body: some View {
        Group {
            if let details = availableDetails {
                resultShell(details: details, academic: academicResult)
                    .onAppear { recentStore.save(details) }
            } else {
                identityLoadingState
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Student Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { width in
            containerWidth = width
        }
        .task(id: rollNumber.rawValue) {
            await academicStore.load(rollNumber: rollNumber)
            if availableDetails == nil {
                // All Results carries the same identity payload. Use it as a
                // fallback so an Academic endpoint failure never hides the shell.
                await loadSectionIfNeeded(.allResults)
            }
        }
        .task(id: selectedSection) {
            await loadSectionIfNeeded(selectedSection)
        }
    }

    private var academicResult: AcademicResult? {
        guard case .loaded(let response) = academicStore.state else { return nil }
        return response.results
    }

    private var availableDetails: StudentDetails? {
        if case .loaded(let response) = academicStore.state, let details = response.details { return details }
        if case .loaded(.allResults(let response)) = allResultsStore.state { return response.details }
        if case .loaded(.backlogs(let response)) = backlogStore.state { return response.details }
        if case .loaded(.credits(let response)) = creditsStore.state { return response.details }
        return nil
    }

    private var fallbackIsLoading: Bool {
        if case .loading = allResultsStore.state { return true }
        return false
    }

    @ViewBuilder
    private var identityLoadingState: some View {
        if fallbackIsLoading {
            AppLoadingView(
                "Confirming student details",
                message: "Checking the available JNTUH records."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch academicStore.state {
            case .idle, .loading:
                AppLoadingView(
                    "Finding student record",
                    message: "Fetching the latest result for \(rollNumber.rawValue)."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .pending(let message):
                ResultStatusView(
                    title: "Result is being prepared",
                    message: message,
                    symbol: "clock.arrow.circlepath",
                    actionTitle: "Check again"
                ) { Task { await retryIdentity() } }
            case .failed(let message):
                ResultStatusView(
                    title: "Couldn’t load student record",
                    message: message,
                    symbol: "wifi.exclamationmark",
                    actionTitle: "Try again"
                ) { Task { await retryIdentity() } }
            case .loaded:
                ResultStatusView(
                    title: "Student record unavailable",
                    message: "No identity details were returned. Check again shortly.",
                    symbol: "person.crop.circle.badge.questionmark",
                    actionTitle: "Check again"
                ) { Task { await retryIdentity() } }
            }
        }
    }

    private func retryIdentity() async {
        loadedSections.remove(.allResults)
        await academicStore.load(rollNumber: rollNumber)
        if availableDetails == nil { await loadSectionIfNeeded(.allResults) }
    }

    @ViewBuilder
    private func resultShell(details: StudentDetails, academic: AcademicResult?) -> some View {
        if horizontalSizeClass == .regular
            && !dynamicTypeSize.isAccessibilitySize
            && containerWidth >= 760 {
            regularWidthShell(details: details, academic: academic)
        } else {
            compactShell(details: details, academic: academic)
        }
    }

    private func regularWidthShell(details: StudentDetails, academic: AcademicResult?) -> some View {
        ScrollView {
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 8) {
                    StudentResultHero(details: details, result: academic)
                    StudentResultSectionPicker(selection: $selectedSection)
                }
                .frame(width: 340)

                VStack(alignment: .leading, spacing: 14) {
                    sectionHeading
                    sectionContent(academic: academic)
                }
                .frame(maxWidth: 760, alignment: .leading)
            }
            .frame(maxWidth: 1140, alignment: .top)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
    }

    private func compactShell(details: StudentDetails, academic: AcademicResult?) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                StudentResultHero(details: details, result: academic)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                StudentResultSectionPicker(selection: $selectedSection)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 14) {
                    sectionHeading
                    sectionContent(academic: academic)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
    }

    private var sectionHeading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedSection.title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text(selectedSection.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 3)
    }

    @ViewBuilder
    private func sectionContent(academic: AcademicResult?) -> some View {
        switch selectedSection {
        case .academic:
            if let academic {
                AcademicResultContent(semesters: academic.semesters)
            } else {
                academicUnavailableContent
            }
        case .allResults:
            extendedContent(
                store: allResultsStore,
                expected: .allResults,
                retry: { loadedSections.remove(.allResults); Task { await loadSectionIfNeeded(.allResults) } }
            )
        case .backlogs:
            extendedContent(
                store: backlogStore,
                expected: .backlogs,
                retry: { loadedSections.remove(.backlogs); Task { await loadSectionIfNeeded(.backlogs) } }
            )
        case .credits:
            extendedContent(
                store: creditsStore,
                expected: .credits,
                retry: { loadedSections.remove(.credits); Task { await loadSectionIfNeeded(.credits) } }
            )
        }
    }

    @ViewBuilder
    private var academicUnavailableContent: some View {
        switch academicStore.state {
        case .idle, .loading:
            AppLoadingView(
                "Preparing academic result",
                message: "Organizing semesters, subjects, and grades."
            )
            .frame(maxWidth: .infinity, minHeight: 260)
        case .pending(let message):
            ResultStatusView(
                title: "Academic result is being prepared",
                message: message,
                symbol: "clock.arrow.circlepath",
                actionTitle: "Check again"
            ) { Task { await academicStore.load(rollNumber: rollNumber) } }
            .frame(minHeight: 280)
        case .failed(let message):
            ResultStatusView(
                title: "Couldn’t load academic result",
                message: message,
                symbol: "wifi.exclamationmark",
                actionTitle: "Try again"
            ) { Task { await academicStore.load(rollNumber: rollNumber) } }
            .frame(minHeight: 280)
        case .loaded:
            ContentUnavailableView(
                "Academic result unavailable",
                systemImage: "graduationcap",
                description: Text("Use All Results, Backlogs, or Credits while the consolidated result is unavailable.")
            )
            .frame(minHeight: 280)
        }
    }

    @ViewBuilder
    private func extendedContent(
        store: ExtendedResultStore,
        expected: StudentResultSection,
        retry: @escaping () -> Void
    ) -> some View {
        switch store.state {
        case .idle, .loading:
            AppLoadingView(
                "Preparing \(expected.title.lowercased())",
                message: "Fetching the latest JNTUH report."
            )
            .frame(maxWidth: .infinity, minHeight: 260)
        case .pending(let message):
            ResultStatusView(
                title: "Result is being prepared",
                message: message,
                symbol: "clock.arrow.circlepath",
                actionTitle: "Check again",
                action: retry
            )
            .frame(minHeight: 280)
        case .unavailable(let message):
            ContentUnavailableView("Not available", systemImage: "info.circle", description: Text(message))
                .frame(minHeight: 280)
        case .failed(let message):
            ResultStatusView(
                title: "Couldn’t load \(expected.title.lowercased())",
                message: message,
                symbol: "wifi.exclamationmark",
                actionTitle: "Try again",
                action: retry
            )
            .frame(minHeight: 280)
        case .loaded(let payload):
            switch payload {
            case .allResults(let response) where expected == .allResults:
                AllResultsContent(response: response)
            case .backlogs(let response) where expected == .backlogs:
                BacklogResultContent(response: response)
            case .credits(let response) where expected == .credits:
                if let summary = response.results {
                    CreditsResultContent(summary: summary)
                } else {
                    ContentUnavailableView(
                        "Credits unavailable",
                        systemImage: "chart.bar",
                        description: Text(response.message ?? "Credit requirements are unavailable for this student.")
                    )
                    .frame(minHeight: 280)
                }
            default:
                ContentUnavailableView("Unexpected response", systemImage: "exclamationmark.triangle")
                    .frame(minHeight: 280)
            }
        }
    }

    private func loadSectionIfNeeded(_ section: StudentResultSection) async {
        guard section != .academic, !loadedSections.contains(section) else { return }
        loadedSections.insert(section)

        let flow: ResultFlow
        let store: ExtendedResultStore
        switch section {
        case .allResults: flow = .allResults; store = allResultsStore
        case .backlogs: flow = .backlogs; store = backlogStore
        case .credits: flow = .credits; store = creditsStore
        case .academic: return
        }

        do {
            let request = try flow.makeRequest(primary: rollNumber.rawValue, secondary: "")
            await store.load(request)
        } catch {
            loadedSections.remove(section)
            store.fail((error as? LocalizedError)?.errorDescription ?? "Unable to prepare this request.")
        }
    }
}

private struct ResultStatusView: View {
    let title: String
    let message: String
    let symbol: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            Button(actionTitle, action: action).buttonStyle(.borderedProminent)
        }
    }
}
