import SwiftUI
import UniformTypeIdentifiers

struct ExtendedResultView: View {
    let request: ResultRequest
    @State private var activeRequest: ResultRequest
    @State private var classRollText: String
    @State private var classMode: ClassResultMode
    @State private var classValidationMessage: String?
    @State private var store = ExtendedResultStore()
    @State private var isPickingProof = false
    @State private var selectedProofURL: URL?
    @State private var isConfirmingProof = false
    @FocusState private var isClassRollFocused: Bool

    init(request: ResultRequest) {
        self.request = request
        _activeRequest = State(initialValue: request)
        _classRollText = State(initialValue: request.primary.rawValue)
        _classMode = State(initialValue: request.classMode ?? .academic)
    }

    var body: some View {
        Group {
            switch store.state {
            case .idle, .loading:
                AppLoadingView(
                    "Preparing \(activeRequest.flow.title.lowercased())",
                    message: "Fetching the latest JNTUH data."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .pending(let message):
                statusView("Result is being prepared", message, "clock.arrow.circlepath")
            case .unavailable(let message):
                statusView("Not available", message, "info.circle")
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn’t load report", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") { Task { await store.load(activeRequest) } }
                        .buttonStyle(.borderedProminent)
                }
            case .loaded(let payload):
                payloadView(payload)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .background {
            Color.appBackground
                .onTapGesture { isClassRollFocused = false }
        }
        .navigationTitle(request.flow.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .task(id: activeRequest.id) { await store.load(activeRequest) }
        .fileImporter(
            isPresented: $isPickingProof,
            allowedContentTypes: [.pdf, .png, .jpeg],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                selectedProofURL = url
                isConfirmingProof = true
            }
        }
        .confirmationDialog(
            "Submit consolidated marksheet?",
            isPresented: $isConfirmingProof,
            titleVisibility: .visible
        ) {
            Button("Upload for review") {
                guard let url = selectedProofURL else { return }
                Task { await store.uploadProof(from: url, rollNumber: activeRequest.primary) }
            }
            Button("Cancel", role: .cancel) { selectedProofURL = nil }
        } message: {
            Text("This submits proof for eligibility review. It does not apply for or award grace marks.")
        }
    }

    private func statusView(_ title: String, _ message: String, _ symbol: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            Button("Check again") { Task { await store.load(activeRequest) } }
                .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func payloadView(_ payload: ExtendedResultPayload) -> some View {
        switch payload {
        case .allResults(let response): allResultsView(response)
        case .backlogs(let response): backlogView(response)
        case .credits(let response): creditsView(response)
        case .contrast(let response): contrastView(response)
        case .classResults(let students): classView(students)
        case .classBacklogs(let students): classBacklogView(students)
        case .grace(let response): graceView(response)
        }
    }

    private func allResultsView(_ response: AllResultsResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                StudentIdentityCard(details: response.details)
                ForEach(response.results) { semester in
                    DisclosureGroup {
                        VStack(spacing: 12) {
                            ForEach(semester.exams) { exam in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(examTitle(exam)).font(.subheadline.bold())
                                        Spacer()
                                        Text(exam.examCode).font(.caption.monospaced()).foregroundStyle(.secondary)
                                    }
                                    ForEach(exam.subjects) { subject in SubjectCompactRow(subject: subject) }
                                }
                                .padding(14)
                                .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding(.top, 12)
                    } label: {
                        Text("Semester \(semester.semester)").font(.headline)
                    }
                    .padding(16)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
    }

    private func backlogView(_ response: BacklogResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                StudentIdentityCard(details: response.details)
                MetricBanner(value: String(response.results.totalBacklogs), label: response.results.totalBacklogs == 1 ? "Active backlog" : "Active backlogs", symbol: "exclamationmark.circle")

                if response.results.semesters.isEmpty {
                    ContentUnavailableView("No backlogs", systemImage: "checkmark.seal", description: Text("Every subject in the synced result history is cleared."))
                        .padding(.top, 24)
                } else {
                    ForEach(response.results.semesters) { semester in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Semester \(semester.semester)").font(.headline)
                            ForEach(semester.subjects) { SubjectCompactRow(subject: $0) }
                        }
                        .padding(16)
                        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(16)
        }
    }

    private func creditsView(_ response: CreditsResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if let details = response.details { StudentIdentityCard(details: details) }
                if let result = response.results {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Credit progress").font(.headline)
                        Text("\(result.totalObtainedCredits.formatted()) of \(result.totalRequiredCredits.formatted()) required credits")
                            .font(.title2.bold())
                        ProgressView(value: result.totalObtainedCredits, total: max(result.totalRequiredCredits, 1))
                            .tint(.primary)
                    }
                    .padding(18)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    ForEach(Array(result.academicYears.enumerated()), id: \.offset) { index, year in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Academic year \(index + 1)").font(.headline)
                                Spacer()
                                Text("\(year.creditsObtained.formatted()) / \(year.totalCredits.formatted())")
                                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            ForEach(year.semesterWiseCredits.sorted(by: { $0.key < $1.key }), id: \.key) { semester, credits in
                                HStack {
                                    Text("Semester \(semester)")
                                    Spacer()
                                    Text(credits.formatted()).monospacedDigit().foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(16)
                        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(16)
        }
    }

    private func contrastView(_ response: ResultContrastResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(response.studentProfiles) { profile in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(profile.name).font(.headline)
                        Text(profile.rollNumber).font(.subheadline.monospaced()).foregroundStyle(.secondary)
                        HStack {
                            MetricPill(label: "CGPA", value: profile.cgpa)
                            MetricPill(label: "Credits", value: profile.credits.formatted())
                            MetricPill(label: "Backlogs", value: profile.backlogs.formatted())
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Text("Semester comparison")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                ForEach(Array(response.semesters.enumerated()), id: \.offset) { index, pair in
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Semester \(pair.first?.semester ?? String(index + 1))").font(.headline)
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(Array(pair.enumerated()), id: \.offset) { studentIndex, semester in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(response.studentProfiles.indices.contains(studentIndex) ? response.studentProfiles[studentIndex].name : "Student \(studentIndex + 1)")
                                        .font(.caption.weight(.semibold)).lineLimit(1)
                                    Text("SGPA \(semester.sgpa)").font(.subheadline.bold())
                                    Text("\(semester.credits) credits").font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(16)
        }
    }

    private var classForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("View an entire class").font(.headline)
                Text("Enter any hall ticket number from the section.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Image(systemName: "person.text.rectangle").foregroundStyle(.secondary)
                TextField("Hall ticket number", text: $classRollText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($isClassRollFocused)
                    .onSubmit { loadClass(mode: classMode) }
                    .onChange(of: classRollText) { _, value in
                        let normalized = String(value.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(10))
                        if normalized != value { classRollText = normalized }
                        classValidationMessage = nil
                    }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 50)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Picker("Result type", selection: $classMode) {
                ForEach(ClassResultMode.allCases) { mode in Text(mode.title).tag(mode) }
            }
            .pickerStyle(.segmented)
            .onChange(of: classMode) { _, mode in
                isClassRollFocused = false
                loadClass(mode: mode)
            }

            if let classValidationMessage {
                Label(classValidationMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.caption).foregroundStyle(.red)
            }

            Button { loadClass(mode: classMode) } label: {
                Label("Load class", systemImage: "person.3.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
            .foregroundStyle(Color.appBackground)
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func loadClass(mode: ClassResultMode) {
        isClassRollFocused = false
        let roll = RollNumber(classRollText)
        guard roll.isValid else {
            classValidationMessage = "Enter a valid 10-character hall ticket number."
            return
        }
        classValidationMessage = nil
        let next = ResultRequest(flow: .classResults, primary: roll, secondary: nil, classMode: mode)
        if next.id == activeRequest.id {
            Task { await store.load(next) }
        } else {
            activeRequest = next
        }
    }

    private func classView(_ students: [ClassResultStudent]) -> some View {
        let cleared = students.compactMap { student -> (ClassResultStudent, Double)? in
            guard let result = student.results,
                  result.backlogs == 0,
                  let cgpa = Double(result.cgpa),
                  cgpa > 0 else { return nil }
            return (student, cgpa)
        }
        .sorted { $0.1 == $1.1 ? $0.0.details.rollNumber < $1.0.details.rollNumber : $0.1 > $1.1 }

        let backlogged = students.filter { ($0.results?.backlogs ?? 0) > 0 }
            .sorted { ($0.results?.backlogs ?? 0) > ($1.results?.backlogs ?? 0) }
        let unsynced = students.filter { $0.results == nil }
            .sorted { $0.details.rollNumber < $1.details.rollNumber }
        let average = cleared.isEmpty ? 0 : cleared.map(\.1).reduce(0, +) / Double(cleared.count)
        let top = cleared.first

        return ScrollView {
            LazyVStack(spacing: 10) {
                classForm
                ClassSummaryCard(
                    studentCount: students.count,
                    average: cleared.isEmpty ? "—" : average.formatted(.number.precision(.fractionLength(2))),
                    topCGPA: top?.1.formatted(.number.precision(.fractionLength(2))) ?? "—",
                    topper: top?.0.details.name
                )

                Label("Partial database snapshot — unsynced students may be missing.", systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                ResultListHeading(title: "Class ranking", detail: "Cleared students by CGPA")
                ForEach(Array(cleared.enumerated()), id: \.element.0.id) { index, entry in
                    ClassAcademicStudentRow(student: entry.0, rank: index + 1, cgpa: entry.1, backlogs: 0)
                }

                if !backlogged.isEmpty {
                    ResultListHeading(title: "Active backlogs", detail: "CGPA not ranked")
                    ForEach(backlogged) { student in
                        ClassAcademicStudentRow(
                            student: student,
                            rank: nil,
                            cgpa: nil,
                            backlogs: student.results?.backlogs ?? 0
                        )
                    }
                }

                if !unsynced.isEmpty {
                    ResultListHeading(title: "Not synced", detail: "Unranked")
                    ForEach(unsynced) { student in
                        ClassAcademicStudentRow(student: student, rank: nil, cgpa: nil, backlogs: nil)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 28)
        }
    }

    private func classBacklogView(_ students: [ClassBacklogStudent]) -> some View {
        let ranked = students.filter { ($0.results?.totalBacklogs ?? 0) > 0 }.sorted {
            let lhs = $0.results?.totalBacklogs ?? 0
            let rhs = $1.results?.totalBacklogs ?? 0
            return lhs == rhs ? $0.details.rollNumber < $1.details.rollNumber : lhs > rhs
        }
        let unsynced = students.filter { $0.results == nil }
            .sorted { $0.details.rollNumber < $1.details.rollNumber }

        return ScrollView {
            LazyVStack(spacing: 10) {
                classForm
                if ranked.isEmpty && unsynced.isEmpty {
                    ContentUnavailableView(
                        "No backlogs in this class 🎉",
                        systemImage: "checkmark.seal",
                        description: Text("Every student has cleared their subjects.")
                    )
                    .frame(minHeight: 280)
                }

                if !ranked.isEmpty {
                    ResultListHeading(title: "\(ranked.count) students with backlogs", detail: "Most backlogs first")
                    ForEach(ranked) { student in
                        classBacklogStudentRow(student, totalBacklogs: student.results?.totalBacklogs)
                    }
                }

                if !unsynced.isEmpty {
                    ResultListHeading(title: "Not synced", detail: "Backlog status unavailable")
                    ForEach(unsynced) { student in
                        classBacklogStudentRow(student, totalBacklogs: nil)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 28)
        }
    }

    private func classBacklogStudentRow(_ student: ClassBacklogStudent, totalBacklogs: Int?) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(student.details.name).font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(student.details.rollNumber).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let totalBacklogs {
                Text("\(totalBacklogs) backlog(s)")
                    .font(.caption.weight(.semibold)).foregroundStyle(.red)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Color.red.opacity(0.10), in: Capsule())
            } else {
                Text("Unavailable")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.10), in: Capsule())
            }
        }
        .padding(14)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func graceView(_ response: GraceEligibilityResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if response.isEligible {
                    MetricBanner(value: String(response.totalBacklogs ?? 0), label: "Potential grace-mark subjects", symbol: "rosette")
                    Text("Your synced final-year backlogs meet the initial eligibility rules. Review the subjects below before submitting proof.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    ForEach(response.semesters ?? []) { semester in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Semester \(semester.semester)").font(.headline)
                            ForEach(semester.subjects) { SubjectCompactRow(subject: $0) }
                        }
                        .padding(16)
                        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    Button {
                        isPickingProof = true
                    } label: {
                        Label("Choose proof to upload", systemImage: "doc.badge.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .foregroundStyle(Color.appBackground)
                    .disabled(isUploadingProof)

                    switch store.proofUploadState {
                    case .idle:
                        Text("PDF, PNG or JPEG · maximum 5 MB")
                            .font(.footnote).foregroundStyle(.secondary)
                    case .uploading:
                        AppLoadingView(
                            "Uploading proof",
                            message: "Keep this screen open until the upload finishes.",
                            compact: true
                        )
                    case .succeeded(let receipt):
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Proof uploaded for review", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                            Text("Receipt: \(receipt.uploadedAt)")
                                .font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                    case .failed(let message):
                        Label(message, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote).foregroundStyle(.red)
                    }
                } else {
                    ContentUnavailableView("Not eligible", systemImage: "rosette", description: Text(response.message ?? "Grace marks are not applicable for this student."))
                }
            }
            .padding(16)
        }
    }

    private var isUploadingProof: Bool {
        if case .uploading = store.proofUploadState { return true }
        return false
    }

    private func examTitle(_ exam: ExamAttempt) -> String {
        if exam.graceMarks { return "Grace marks" }
        if exam.rcrv { return "RCRV / revaluation" }
        return "Exam attempt"
    }
}

private struct StudentIdentityCard: View {
    let details: StudentDetails
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(details.name).font(.title3.bold())
            Text(details.rollNumber).font(.subheadline.monospaced()).foregroundStyle(.secondary)
            Text(details.branch).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SubjectCompactRow: View {
    let subject: Subject
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(subject.subjectName).font(.subheadline.weight(.medium))
                Text(subject.subjectCode).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(subject.grade).font(.headline)
                Text("\(subject.totalMarks)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
    }
}

private struct MetricBanner: View {
    let value: String
    let label: String
    let symbol: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.largeTitle.bold().monospacedDigit())
                Text(label).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ClassSummaryCard: View {
    let studentCount: Int
    let average: String
    let topCGPA: String
    let topper: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.3.fill")
                    .frame(width: 40, height: 40)
                    .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("Class summary").font(.headline)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { metrics }
                VStack(spacing: 8) { metrics }
            }

            if let topper {
                Divider()
                Label("Topper: \(topper)", systemImage: "trophy.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.72, green: 0.50, blue: 0.16))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder private var metrics: some View {
        ClassMetric(value: String(studentCount), label: "Students")
        ClassMetric(value: average, label: "Avg CGPA")
        ClassMetric(value: topCGPA, label: "Top CGPA")
    }
}

private struct ResultListHeading: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.headline)
            Spacer(minLength: 8)
            Text(detail).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct ClassAcademicStudentRow: View {
    let student: ClassResultStudent
    let rank: Int?
    let cgpa: Double?
    let backlogs: Int?

    var body: some View {
        HStack(spacing: 12) {
            if let rank {
                ClassRankBadge(rank: rank)
            } else {
                Image(systemName: backlogs == nil ? "questionmark" : "exclamationmark")
                    .font(.caption.bold())
                    .foregroundStyle(backlogs == nil ? Color.secondary : Color.red)
                    .frame(width: 38, height: 38)
                    .background(Color.primary.opacity(0.055), in: Circle())
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(student.details.name).font(.subheadline.weight(.semibold))
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text(student.details.rollNumber).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)

            if let cgpa {
                Text("CGPA \(cgpa.formatted(.number.precision(.fractionLength(2))))")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Color.primary.opacity(0.07), in: Capsule())
            } else if let backlogs {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("CGPA —").font(.caption.bold().monospacedDigit())
                    Text("\(backlogs) backlog(s)").font(.caption2.weight(.semibold)).foregroundStyle(.red)
                }
            } else {
                Text("Not synced").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct ClassRankBadge: View {
    let rank: Int

    private var fill: Color {
        switch rank {
        case 1: Color(red: 0.95, green: 0.63, blue: 0.08)
        case 2: Color(red: 0.62, green: 0.69, blue: 0.78)
        case 3: Color(red: 0.78, green: 0.34, blue: 0.05)
        default: Color.primary.opacity(0.06)
        }
    }

    var body: some View {
        Text(String(rank))
            .font(.subheadline.bold().monospacedDigit())
            .foregroundStyle(rank <= 3 ? .white : .primary)
            .frame(width: 38, height: 38)
            .background(fill, in: Circle())
            .accessibilityLabel("Rank \(rank)")
    }
}

private struct ClassMetric: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MetricPill: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.subheadline.bold().monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
