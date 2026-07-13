import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var recentStore: RecentSearchStore
    let onNavigate: (AppRoute) -> Void
    @State private var rollText = ""
    @State private var selectedFlow: ResultFlow?
    @State private var validationMessage: String?
    @State private var isTopGlassVisible = false
    @FocusState private var isRollFieldFocused: Bool

    private var toolColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            [GridItem(.flexible())]
        } else {
            [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if horizontalSizeClass == .regular {
                    VStack(spacing: 24) {
                        hero
                        HStack(alignment: .top, spacing: 24) {
                            quickTools.frame(maxWidth: .infinity, alignment: .top)
                            recentSearches.frame(width: 400, alignment: .top)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 80)
                    }
                    .frame(maxWidth: 1180)
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 0) {
                        hero
                        VStack(spacing: 28) {
                            quickTools
                            recentSearches
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 112)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onScrollPhaseChange { _, phase in
                if phase.isScrolling {
                    isRollFieldFocused = false
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
        .background {
            Color.appBackground
                .onTapGesture { isRollFieldFocused = false }
        }
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
        .alert("Check hall ticket number", isPresented: Binding(
            get: { validationMessage != nil },
            set: { if !$0 { validationMessage = nil } }
        )) {
            Button("OK", role: .cancel) { validationMessage = nil }
        } message: {
            Text(validationMessage ?? "")
        }
        .navigationTitle("Home")
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var hero: some View {
        if dynamicTypeSize.isAccessibilitySize {
            accessibilityHero
        } else {
            standardHero
        }
    }

    private var standardHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                appMark

                Text("JNTUH Connect")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("Student portal")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(.top, 56)
            .contentShape(Rectangle())
            .onTapGesture { isRollFieldFocused = false }

            VStack(alignment: .leading, spacing: 8) {
                Text(horizontalSizeClass == .regular ? "Your academic record, made simple." : "Your academic record,\nmade simple.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .tracking(-0.7)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Search results, backlogs and credits with your hall ticket number.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(2)
            }
            .padding(.top, 30)

            searchPanel
                .padding(.top, 22)
                .frame(maxWidth: horizontalSizeClass == .regular ? 680 : .infinity)
        }
        .heroStyle(colorScheme: colorScheme)
    }

    private var accessibilityHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                appMark
                Text("JNTUH Connect")
                    .font(.headline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 56)
            .contentShape(Rectangle())
            .onTapGesture { isRollFieldFocused = false }

            Text("Find your academic results")
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            Text("Enter your hall ticket number below.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            searchPanel
        }
        .heroStyle(colorScheme: colorScheme)
    }

    private var appMark: some View {
        Image("AppMark")
            .resizable()
            .scaledToFit()
            .frame(width: 34, height: 34)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .accessibilityHidden(true)
    }

    private var searchPanel: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    searchField
                    searchButton
                }
            } else {
                HStack(spacing: 10) {
                    searchField
                    searchButton
                }
            }
        }
        .padding(10)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .accessibilityHidden(true)

            TextField(
                "",
                text: $rollText,
                prompt: Text("Hall ticket number").foregroundStyle(.white.opacity(0.55))
            )
            .foregroundStyle(.white)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .focused($isRollFieldFocused)
            .onSubmit(search)
            .onChange(of: rollText) { _, value in
                let normalized = String(value.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(10))
                if normalized != value { rollText = normalized }
                validationMessage = nil
            }
            .accessibilityLabel("Hall ticket number")
            .accessibilityHint("Enter your ten-character JNTUH hall ticket number")
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var searchButton: some View {
        Button(action: search) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    Label("View result", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
            }
            .frame(minWidth: 50, minHeight: 50)
        }
        .buttonStyle(.plain)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .foregroundStyle(.black)
        .disabled(!RollNumber(rollText).isValid)
        .opacity(RollNumber(rollText).isValid ? 1 : 0.55)
        .accessibilityLabel("View result")
    }

    private var quickTools: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(
                title: "Quick tools",
                subtitle: "Common academic checks"
            )

            LazyVGrid(columns: toolColumns, spacing: 12) {
                ForEach(QuickToolDestination.allCases) { tool in
                    QuickToolCard(tool: tool) {
                        isRollFieldFocused = false
                        selectedFlow = tool.flow
                    }
                }
            }
        }
    }

    private var recentSearches: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                sectionHeading(
                    title: "Recent searches",
                    subtitle: recentStore.students.isEmpty ? "Students you open will appear here" : "Your latest student records"
                )

                Spacer(minLength: 12)

                if !recentStore.students.isEmpty {
                    Button("Clear", role: .destructive) {
                        recentStore.clear()
                    }
                    .font(.subheadline.weight(.medium))
                }
            }

            if recentStore.students.isEmpty {
                EmptyRecentCard()
            } else {
                VStack(spacing: 10) {
                    ForEach(recentStore.students, id: \.rollNumber) { student in
                        Button {
                            isRollFieldFocused = false
                            onNavigate(.student(RollNumber(student.rollNumber), .academic))
                        } label: {
                            RecentStudentRow(student: student)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func search() {
        isRollFieldFocused = false
        let roll = RollNumber(rollText)
        guard roll.isValid else {
            validationMessage = "Enter a valid 10-character hall ticket number."
            return
        }
        rollText = roll.rawValue
        onNavigate(.student(roll, .academic))
    }
}

private struct QuickToolCard: View {
    let tool: QuickToolDestination
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: tool.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tool.color)
                    .frame(width: 40, height: 40)
                    .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(tool.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
            .padding(14)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.appOutline.opacity(0.38), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.quick.\(tool.flow.rawValue)")
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct EmptyRecentCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.055), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Nothing here yet")
                    .font(.subheadline.weight(.semibold))
                Text("Search a student above to keep a private shortcut on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.appOutline.opacity(0.38), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct RecentStudentRow: View {
    let student: RecentStudent

    var body: some View {
        HStack(spacing: 14) {
            Text(student.name.initials)
                .font(.subheadline.bold())
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.065), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(student.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(student.rollNumber) · \(student.branch)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.appOutline.opacity(0.38), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
    }
}

private enum QuickToolDestination: String, CaseIterable, Identifiable {
    case contrast, classResult, graceMarks, credits

    var id: Self { self }

    var title: String {
        switch self {
        case .contrast: "Result contrast"
        case .classResult: "Class result"
        case .graceMarks: "Grace marks"
        case .credits: "Credits"
        }
    }

    var subtitle: String {
        switch self {
        case .contrast: "Compare students"
        case .classResult: "Rank a section"
        case .graceMarks: "Check eligibility"
        case .credits: "Track progress"
        }
    }

    var icon: String {
        switch self {
        case .contrast: "arrow.left.arrow.right"
        case .classResult: "person.3"
        case .graceMarks: "rosette"
        case .credits: "chart.bar"
        }
    }

    var flow: ResultFlow {
        switch self {
        case .contrast: .contrast
        case .classResult: .classResults
        case .graceMarks: .graceMarks
        case .credits: .credits
        }
    }

    var color: Color {
        switch self {
        case .contrast: .purple
        case .classResult: .blue
        case .graceMarks: .green
        case .credits: .orange
        }
    }
}

private extension View {
    func heroStyle(colorScheme: ColorScheme) -> some View {
        foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.bottom, 26)
            .background(AppTheme.heroGradient(for: colorScheme))
    }
}

private extension String {
    var initials: String {
        split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}
