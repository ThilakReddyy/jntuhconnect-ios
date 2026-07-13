import Foundation

struct ResultRequest: Identifiable, Hashable, Sendable {
    let flow: ResultFlow
    let primary: RollNumber
    let secondary: RollNumber?
    let classMode: ClassResultMode?

    var id: String { flow.rawValue + primary.rawValue + (secondary?.rawValue ?? "") + (classMode?.rawValue ?? "") }
}

enum ClassResultMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case academic = "academicresult"
    case backlogs = "backlog"
    var id: Self { self }
    var title: String { self == .academic ? "Academic" : "Backlogs" }
}

enum ResultFlow: String, CaseIterable, Identifiable, Hashable, Sendable {
    case academic
    case allResults
    case backlogs
    case credits
    case contrast
    case classResults
    case graceMarks

    var id: Self { self }

    var title: String {
        switch self {
        case .academic: "Academic result"
        case .allResults: "All results"
        case .backlogs: "Backlog report"
        case .credits: "Credits checker"
        case .contrast: "Result contrast"
        case .classResults: "Class result"
        case .graceMarks: "Grace marks"
        }
    }

    var prompt: String {
        switch self {
        case .academic: "View your consolidated marks, SGPA and CGPA."
        case .allResults: "See every regular, supplementary, RCRV and grace attempt."
        case .backlogs: "Find subjects that are still not cleared."
        case .credits: "Compare obtained credits with your regulation requirement."
        case .contrast: "Compare two students from the same regulation, year and branch."
        case .classResults: "Enter any hall ticket number from the class section."
        case .graceMarks: "Check final-year grace-marks eligibility."
        }
    }

    var symbol: String {
        switch self {
        case .academic: "graduationcap"
        case .allResults: "books.vertical"
        case .backlogs: "exclamationmark.circle"
        case .credits: "chart.bar"
        case .contrast: "arrow.left.arrow.right"
        case .classResults: "person.3"
        case .graceMarks: "rosette"
        }
    }

    var needsSecondRollNumber: Bool { self == .contrast }

    func makeRequest(primary: String, secondary: String, classMode: ClassResultMode = .academic) throws -> ResultRequest {
        let first = RollNumber(primary)
        guard first.isValid else { throw ResultFlowValidationError.invalidPrimary }
        if self == .graceMarks,
           let batch = Int(first.rawValue.prefix(2)),
           batch >= 22 {
            throw ResultFlowValidationError.graceBatchPaused
        }
        guard needsSecondRollNumber else {
            return ResultRequest(flow: self, primary: first, secondary: nil, classMode: self == .classResults ? classMode : nil)
        }

        let second = RollNumber(secondary)
        guard second.isValid else { throw ResultFlowValidationError.invalidSecondary }
        guard first != second else { throw ResultFlowValidationError.sameRollNumbers }
        return ResultRequest(flow: self, primary: first, secondary: second, classMode: nil)
    }
}

enum ResultFlowValidationError: LocalizedError {
    case invalidPrimary
    case invalidSecondary
    case sameRollNumbers
    case graceBatchPaused

    var errorDescription: String? {
        switch self {
        case .invalidPrimary: "Enter a valid 10-character hall ticket number."
        case .invalidSecondary: "Enter a valid second hall ticket number."
        case .sameRollNumbers: "Enter two different hall ticket numbers."
        case .graceBatchPaused: "Grace-marks proof submission is currently paused for 2022 and newer batches."
        }
    }
}
