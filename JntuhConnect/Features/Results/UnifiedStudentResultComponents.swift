import SwiftUI

enum StudentResultSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case allResults
    case academic
    case backlogs
    case credits

    var id: Self { self }

    var title: String {
        switch self {
        case .allResults: "All Results"
        case .academic: "Academic"
        case .backlogs: "Backlogs"
        case .credits: "Credits"
        }
    }

    var subtitle: String {
        switch self {
        case .allResults: "Every published attempt, subject mark and official JNTUH result link."
        case .academic: "Your consolidated best attempt, semester performance and complete subject breakdown."
        case .backlogs: "Active subjects still to clear, grouped by the semester where they belong."
        case .credits: "Overall, year-wise and semester-wise progress toward your regulation requirement."
        }
    }

    init?(flow: ResultFlow) {
        switch flow {
        case .academic: self = .academic
        case .allResults: self = .allResults
        case .backlogs: self = .backlogs
        case .credits: self = .credits
        default: return nil
        }
    }
}

struct StudentResultHero: View {
    let details: StudentDetails
    let result: AcademicResult?
    @State private var showsAccessibleDetails = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    private var cgpaText: String {
        guard let result else { return "—" }
        return result.backlogs > 0 ? "—" : result.cgpa
    }
    private var cgpaProgress: Double { min(max((Double(result?.cgpa ?? "") ?? 0) / 10, 0), 1) }
    private var summaryText: String {
        guard let result else { return "Academic summary unavailable. Other result sections remain accessible." }
        return "CGPA \(cgpaText) · \(result.credits.compactNumber) credits · \(result.backlogs) backlog\(result.backlogs == 1 ? "" : "s") · \(result.semesters.count) semesters"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 14 : 20) {
            if dynamicTypeSize.isAccessibilitySize {
                Text(details.name)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text(details.rollNumber)
                    .font(.headline.monospaced())

                DisclosureGroup(isExpanded: $showsAccessibleDetails) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(details.branch)
                        Text("College \(details.collegeCode)")
                        Text(summaryText)
                            .font(.headline)
                            .accessibilityLabel("Academic summary, \(summaryText)")
                    }
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.top, 10)
                } label: {
                    Text("Student details")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .tint(.white)
                .accessibilityHint(showsAccessibleDetails ? "Collapses student details" : "Shows branch, college and academic summary")
            } else {
                HStack(alignment: .center, spacing: 16) {
                    identity.frame(maxWidth: .infinity, alignment: .leading)
                    cgpaRing
                }
                HStack(spacing: 10) {
                    HeroMetric(value: result?.credits.compactNumber ?? "—", label: "Credits")
                    HeroMetric(value: result.map { String($0.backlogs) } ?? "—", label: "Backlogs")
                    HeroMetric(value: result.map { String($0.semesters.count) } ?? "—", label: "Semesters")
                }
            }
        }
        .padding(20)
        .foregroundStyle(.white)
        .background(AppTheme.heroGradient(for: colorScheme), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(colorScheme == .dark ? 0.14 : 0.06), lineWidth: 0.75)
        }
        .accessibilityElement(children: .contain)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(details.name)
                .font(.title3.weight(.heavy))
                .textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)
            Text(details.rollNumber)
                .font(.subheadline.monospaced().weight(.semibold))
            Text(details.branch)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
            Text("College \(details.collegeCode)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var cgpaRing: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.18), lineWidth: 8)
            Circle()
                .trim(from: 0, to: cgpaProgress)
                .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(cgpaText).font(.title3.bold().monospacedDigit())
                Text("CGPA").font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(width: 96, height: 96)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("CGPA \(cgpaText)")
    }
}

private struct HeroMetric: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.headline.bold().monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct StudentResultSectionPicker: View {
    @Binding var selection: StudentResultSection
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                Menu {
                    ForEach(StudentResultSection.allCases) { section in
                        Button {
                            selection = section
                        } label: {
                            if selection == section {
                                Label(section.title, systemImage: "checkmark")
                            } else {
                                Text(section.title)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Result section")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selection.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.appOutline.opacity(0.45), lineWidth: 0.5)
                    }
                }
                .accessibilityLabel(selection.title)
                .accessibilityHint("Choose All Results, Academic, Backlogs, or Credits")
            } else {
                HStack(spacing: 4) {
                    ForEach(StudentResultSection.allCases) { section in
                        sectionButton(section).frame(maxWidth: .infinity)
                    }
                }
                .padding(4)
                .background(Color.appSurface, in: Capsule())
            }
        }
        .padding(.vertical, 8)
    }

    private func sectionButton(_ section: StudentResultSection) -> some View {
        Button {
            if reduceMotion { selection = section }
            else { withAnimation(.snappy(duration: 0.22)) { selection = section } }
        } label: {
            Text(section.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .fixedSize(horizontal: dynamicTypeSize.isAccessibilitySize, vertical: false)
                .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 20 : 0)
                .frame(
                    maxWidth: dynamicTypeSize.isAccessibilitySize ? nil : .infinity,
                    minHeight: dynamicTypeSize.isAccessibilitySize ? 56 : 44
                )
                .foregroundStyle(selection == section ? (colorScheme == .dark ? Color.primary : Color.white) : .secondary)
                .background(
                    selection == section
                        ? (colorScheme == .dark ? Color.primary.opacity(0.14) : Color.primary)
                        : .clear,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == section ? .isSelected : [])
    }
}

struct AcademicResultContent: View {
    let semesters: [Semester]

    var body: some View {
        if semesters.isEmpty {
            ContentUnavailableView(
                "No academic results published",
                systemImage: "graduationcap",
                description: Text("No consolidated semester results are available for this student yet.")
            )
            .frame(minHeight: 260)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(Array(semesters.enumerated()), id: \.element.id) { index, semester in
                    AcademicSemesterCard(semester: semester, initiallyExpanded: index == 0)
                }
            }
        }
    }
}

private struct AcademicSemesterCard: View {
    let semester: Semester
    @State private var isExpanded: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(semester: Semester, initiallyExpanded: Bool) {
        self.semester = semester
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 0) {
                ForEach(Array(semester.subjects.enumerated()), id: \.element.id) { index, subject in
                    SubjectResultRow(subject: subject, replacesZeroMarks: true)
                    if index < semester.subjects.count - 1 { Divider() }
                }
            }
            .padding(.top, 12)
        } label: {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    semesterTitle
                    sgpaBadge
                }
            } else {
                HStack(spacing: 12) {
                    semesterTitle
                    Spacer()
                    sgpaBadge
                }
            }
        }
        .tint(.secondary)
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var semesterTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Semester \(semester.semester)").font(.headline)
            Text("\(semester.semesterCredits.compactNumber) credits · \(semester.subjects.count) subjects")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var sgpaBadge: some View {
        Text("SGPA \(semester.semesterSGPA)")
            .font(.caption.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.primary.opacity(0.07), in: Capsule())
    }
}

struct AllResultsContent: View {
    let response: AllResultsResponse

    var body: some View {
        if response.results.isEmpty {
            ContentUnavailableView(
                "No result attempts found",
                systemImage: "doc.text.magnifyingglass",
                description: Text("No published exam attempts were returned for this student.")
            )
            .frame(minHeight: 260)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(response.results) { semester in
                    AllResultSemesterCard(
                        semester: semester,
                        rollNumber: response.details.rollNumber
                    )
                }
            }
        }
    }
}

private struct AllResultSemesterCard: View {
    let semester: AllResultSemester
    let rollNumber: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Semester \(semester.semester)").font(.headline)
                Spacer()
                Text("\(semester.exams.count) attempt\(semester.exams.count == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(semester.exams) { exam in
                    ExamAttemptCard(exam: exam, rollNumber: rollNumber)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ExamAttemptCard: View {
    let exam: ExamAttempt
    let rollNumber: String
    @State private var presentedURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Exam \(exam.examCode)").font(.subheadline.weight(.semibold))
                if exam.rcrv { StatusChip("RCRV", color: .orange) }
                if exam.graceMarks { StatusChip("Grace", color: .purple) }
                Spacer()
                if let url = officialResultURL {
                    Button { presentedURL = url } label: {
                        Label("Official", systemImage: "arrow.up.right.square")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            ForEach(Array(exam.subjects.enumerated()), id: \.element.id) { index, subject in
                SubjectResultRow(subject: subject, replacesZeroMarks: false)
                if index < exam.subjects.count - 1 { Divider() }
            }
        }
        .sheet(item: $presentedURL) { InAppBrowser(url: $0).ignoresSafeArea() }
    }

    private var officialResultURL: URL? {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "results.jntuh.ac.in"
        components.path = "/results/resultAction"
        let degree = rollNumber.count > 5 && Array(rollNumber)[5] == "R" ? "bpharmacy" : "btech"
        components.queryItems = [
            URLQueryItem(name: "degree", value: degree),
            URLQueryItem(name: "examCode", value: exam.examCode),
            URLQueryItem(name: "etype", value: "r16"),
            URLQueryItem(name: "result", value: exam.rcrv ? "gradercrv" : "null"),
            URLQueryItem(name: "grad", value: "null"),
            URLQueryItem(name: "type", value: exam.rcrv ? "rcrvintgrade" : "intgrade"),
            URLQueryItem(name: "htno", value: rollNumber)
        ]
        return components.url
    }
}

struct BacklogResultContent: View {
    let response: BacklogResponse

    var body: some View {
        LazyVStack(spacing: 12) {
            if response.results.totalBacklogs == 0 {
                ContentUnavailableView(
                    "No backlogs 🎉",
                    systemImage: "checkmark.seal",
                    description: Text("Every subject has been cleared. Keep it up!")
                )
                .frame(minHeight: 260)
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "exclamationmark.circle.fill").font(.title2).foregroundStyle(.red)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(response.results.totalBacklogs) active backlog\(response.results.totalBacklogs == 1 ? "" : "s")")
                            .font(.headline).foregroundStyle(.red)
                        Text("Subjects awaiting a clear across \(response.results.semesters.count) semester\(response.results.semesters.count == 1 ? "" : "s").")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.red.opacity(0.22), lineWidth: 0.75)
                }

                ForEach(Array(response.results.semesters.enumerated()), id: \.element.id) { index, semester in
                    BacklogSemesterCard(semester: semester, initiallyExpanded: index == 0)
                }
            }
        }
    }
}

private struct BacklogSemesterCard: View {
    let semester: Semester
    @State private var isExpanded: Bool

    init(semester: Semester, initiallyExpanded: Bool) {
        self.semester = semester
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 0) {
                ForEach(Array(semester.subjects.enumerated()), id: \.element.id) { index, subject in
                    SubjectResultRow(subject: subject, replacesZeroMarks: true)
                    if index < semester.subjects.count - 1 { Divider() }
                }
            }
            .padding(.top, 12)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Semester \(semester.semester)").font(.headline)
                    Text("\(semester.semesterCredits.compactNumber) credits · \(semester.subjects.count) subject\(semester.subjects.count == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(semester.backlogs)) backlog\(Int(semester.backlogs) == 1 ? "" : "s")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.red.opacity(0.10), in: Capsule())
            }
        }
        .tint(.secondary)
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct CreditsResultContent: View {
    let summary: CreditsSummary

    private var progress: Double {
        guard summary.totalRequiredCredits > 0 else { return 0 }
        return min(max(summary.totalObtainedCredits / summary.totalRequiredCredits, 0), 1)
    }

    private var remaining: Double { max(summary.totalRequiredCredits - summary.totalObtainedCredits, 0) }

    var body: some View {
        LazyVStack(spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) { progressRing; progressCopy }
                VStack(alignment: .leading, spacing: 16) { progressRing; progressCopy }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            ForEach(Array(summary.academicYears.enumerated()), id: \.offset) { index, year in
                CreditYearCard(index: index + 1, year: year)
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.12), lineWidth: 8)
            Circle().trim(from: 0, to: progress)
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(Int(progress * 100))%").font(.headline.bold().monospacedDigit())
                Text("Earned").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(width: 108, height: 108)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Credit progress")
        .accessibilityValue("\(summary.totalObtainedCredits.compactNumber) of \(summary.totalRequiredCredits.compactNumber) credits earned, \(remaining.compactNumber) remaining")
    }

    private var progressCopy: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Credit progress").font(.headline)
            Text("\(summary.totalObtainedCredits.compactNumber) of \(summary.totalRequiredCredits.compactNumber) required credits earned")
                .font(.subheadline).foregroundStyle(.secondary)
            Text(remaining == 0 ? "Requirement completed" : "\(remaining.compactNumber) to go")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.primary.opacity(0.07), in: Capsule())
        }
    }
}

private struct CreditYearCard: View {
    let index: Int
    let year: AcademicYearCredits

    private var progress: Double {
        guard year.totalCredits > 0 else { return 0 }
        return min(max(year.creditsObtained / year.totalCredits, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Year \(index)").font(.headline)
            HStack {
                Text("Credits earned").font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(year.creditsObtained.compactNumber) / \(year.totalCredits.compactNumber)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            ProgressView(value: progress).tint(.primary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(year.semesterWiseCredits.keys.sorted(), id: \.self) { semester in
                    Text("Sem \(semester) · \((year.semesterWiseCredits[semester] ?? 0).compactNumber) cr")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.primary.opacity(0.065), in: Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SubjectResultRow: View {
    let subject: Subject
    let replacesZeroMarks: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(subject.subjectCode).font(.caption.monospaced().weight(.semibold))
                Text(subject.subjectName).font(.subheadline.weight(.medium)).fixedSize(horizontal: false, vertical: true)
                Text("Int \(mark(subject.internalMarks)) · Ext \(mark(subject.externalMarks)) · Total \(mark(subject.totalMarks))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(subject.grade)
                    .font(.caption.bold())
                    .foregroundStyle(gradeColor)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(gradeColor.opacity(0.12), in: Capsule())
                Text("\(subject.credits.compactNumber) cr").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }

    private var gradeColor: Color {
        if colorScheme == .dark {
            switch subject.grade.uppercased() {
            case "F", "AB": return Color(red: 1.0, green: 0.42, blue: 0.42)
            case "O", "A+", "A": return Color(red: 0.46, green: 0.83, blue: 0.62)
            case "B+", "B": return Color(red: 0.56, green: 0.76, blue: 0.98)
            case "C": return Color(red: 0.91, green: 0.75, blue: 0.39)
            case "D": return Color(red: 0.98, green: 0.59, blue: 0.43)
            default: return .secondary
            }
        }
        switch subject.grade.uppercased() {
        case "F", "AB": return .red
        case "O", "A+", "A": return Color(red: 0.25, green: 0.50, blue: 0.40)
        case "B+", "B": return Color(red: 0.35, green: 0.49, blue: 0.60)
        case "C": return Color(red: 0.61, green: 0.48, blue: 0.26)
        case "D": return Color(red: 0.67, green: 0.40, blue: 0.28)
        default: return .secondary
        }
    }

    private func mark(_ value: Int) -> String {
        replacesZeroMarks && value == 0 ? "—" : String(value)
    }
}

private struct StatusChip: View {
    let text: String
    let color: Color
    init(_ text: String, color: Color) { self.text = text; self.color = color }
    var body: some View {
        Text(text).font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private extension Double {
    var compactNumber: String {
        rounded() == self ? String(Int(self)) : formatted(.number.precision(.fractionLength(1)))
    }
}
