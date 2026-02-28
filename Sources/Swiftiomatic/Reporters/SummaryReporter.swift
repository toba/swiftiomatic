import Foundation

/// Reports a summary table of all violations
struct SummaryReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "summary"
    static let isRealtime = false

    static let description = "Reports a summary table of all violations."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        SummaryTable(violations: violations).render()
    }
}

// MARK: - Table Rendering

private struct SummaryTable {
    private struct Column {
        let header: String
        var width: Int
    }

    private var columns: [Column]
    private var rows: [[String]]

    // swiftlint:disable:next function_body_length
    init(violations: [StyleViolation]) {
        let numberOfWarningsHeader = "warnings"
        let numberOfErrorsHeader = "errors"
        let numberOfViolationsHeader = "total violations"
        let numberOfFilesHeader = "number of files"
        let headers = [
            "rule identifier",
            "opt-in",
            "correctable",
            "custom",
            numberOfWarningsHeader,
            numberOfErrorsHeader,
            numberOfViolationsHeader,
            numberOfFilesHeader,
        ]
        columns = headers.map { Column(header: $0, width: $0.count) }
        rows = []

        let ruleIdentifiersToViolationsMap = violations.group { $0.ruleIdentifier }
        let sortedRuleIdentifiers = ruleIdentifiersToViolationsMap.sorted { lhs, rhs in
            let count1 = lhs.value.count
            let count2 = rhs.value.count
            if count1 > count2 {
                return true
            }
            if count1 == count2 {
                return lhs.key < rhs.key
            }
            return false
        }.map(\.key)

        var totalNumberOfWarnings = 0
        var totalNumberOfErrors = 0

        for ruleIdentifier in sortedRuleIdentifiers {
            guard
                let ruleIdentifier = ruleIdentifiersToViolationsMap[ruleIdentifier]?.first?
                .ruleIdentifier
            else {
                continue
            }

            let rule = RuleRegistry.shared.rule(forID: ruleIdentifier)
            let ruleViolations = ruleIdentifiersToViolationsMap[ruleIdentifier] ?? []
            let numberOfWarnings = ruleViolations.count(where: { $0.severity == .warning })
            let numberOfErrors = ruleViolations.count(where: { $0.severity == .error })
            let numberOfViolations = numberOfWarnings + numberOfErrors
            totalNumberOfWarnings += numberOfWarnings
            totalNumberOfErrors += numberOfErrors
            let numberOfFiles = Set(ruleViolations.map(\.location.file)).count

            addRow([
                ruleIdentifier,
                rule is any OptInRule.Type ? "yes" : "no",
                rule is any CorrectableRule.Type ? "yes" : "no",
                rule == nil ? "yes" : "no",
                numberOfWarnings.formattedString.leftPadded(forHeader: numberOfWarningsHeader),
                numberOfErrors.formattedString.leftPadded(forHeader: numberOfErrorsHeader),
                numberOfViolations.formattedString.leftPadded(forHeader: numberOfViolationsHeader),
                numberOfFiles.formattedString.leftPadded(forHeader: numberOfFilesHeader),
            ])
        }

        let totalNumberOfViolations = totalNumberOfWarnings + totalNumberOfErrors
        let totalNumberOfFiles = Set(violations.map(\.location.file)).count
        addRow([
            "Total",
            "",
            "",
            "",
            totalNumberOfWarnings.formattedString.leftPadded(forHeader: numberOfWarningsHeader),
            totalNumberOfErrors.formattedString.leftPadded(forHeader: numberOfErrorsHeader),
            totalNumberOfViolations.formattedString.leftPadded(forHeader: numberOfViolationsHeader),
            totalNumberOfFiles.formattedString.leftPadded(forHeader: numberOfFilesHeader),
        ])
    }

    private mutating func addRow(_ values: [String]) {
        for (index, value) in values.enumerated() where index < columns.count {
            columns[index].width = max(columns[index].width, value.count)
        }
        rows.append(values)
    }

    func render() -> String {
        let separator = "+-" + columns.map { String(repeating: "-", count: $0.width) }
            .joined(separator: "-+-") + "-+"
        let headerLine = "| " + columns.map { $0.header.padding(toLength: $0.width, withPad: " ", startingAt: 0) }
            .joined(separator: " | ") + " |"

        var lines = [separator, headerLine, separator]
        for (index, row) in rows.enumerated() {
            let cells = columns.enumerated().map { colIndex, col in
                let value = colIndex < row.count ? row[colIndex] : ""
                return value.padding(toLength: col.width, withPad: " ", startingAt: 0)
            }
            // Insert extra separator before the last row (Total)
            if index == rows.count - 1 {
                lines.append(separator)
            }
            lines.append("| " + cells.joined(separator: " | ") + " |")
        }
        lines.append(separator)
        return lines.joined(separator: "\n")
    }
}

private extension String {
    func leftPadded(forHeader header: String) -> String {
        let headerCount = header.count - count
        if headerCount > 0 {
            return String(repeating: " ", count: headerCount) + self
        }
        return self
    }
}

extension Int {
    private static let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    fileprivate var formattedString: String {
        // swiftlint:disable:next legacy_objc_type
        Int.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
