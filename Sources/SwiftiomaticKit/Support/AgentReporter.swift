import Foundation
import Synchronization
import TobaConcurrency

/// Collects lint findings and renders them as compact JSON for an agent to triage.
///
/// The report has one entry per rule per file. Each entry lists its locations in an `evidence`
/// array, and each location names the role it matched. Rule metadata appears once, in `rules`, so a
/// rule that fires in many files does not repeat its applicability. The report carries no URIs.
///
/// ```json
/// { "rules": { "noNestedWithLock": { "guidance": "MUST", "applicability": "..." } },
///   "findings": [
///     { "file": "Sources/A.swift", "rule": "noNestedWithLock", "severity": "warning",
///       "guidance": "MUST", "message": "...", "status": "introduced",
///       "evidence": [ { "role": "finding", "line": 12, "column": 5, "status": "introduced" },
///                     { "role": "owner", "line": 9, "column": 3, "message": "..." } ] } ] }
/// ```
///
/// `status` appears only when the run has changed line ranges. An evidence `message` appears only
/// when it differs from the entry's `message`, and an evidence `file` only when it differs from the
/// entry's `file`.
public final class AgentLintReporter: Sendable {
    /// One diagnostic as the lint command records it.
    public struct Entry: Sendable {
        public let file: String?
        public let line: Int?
        public let column: Int?
        /// `error`, `warning` or `note`.
        public let severity: String
        public let ruleID: String
        public let message: String
        public let status: ChangeStatus?
        /// The notes of the finding, as role-tagged locations.
        public let evidence: [LintEvidence]

        public init(
            file: String?,
            line: Int?,
            column: Int?,
            severity: String,
            ruleID: String,
            message: String,
            status: ChangeStatus? = nil,
            evidence: [LintEvidence] = []
        ) {
            self.file = file
            self.line = line
            self.column = column
            self.severity = severity
            self.ruleID = ruleID
            self.message = message
            self.status = status
            self.evidence = evidence
        }
    }

    private let paths: WorkingDirectoryPaths
    private let entries = Mutex<[Entry]>([])

    /// - Parameter workingDirectory: The directory that relative file paths start from.
    public init(
        workingDirectory: URL = .init(fileURLWithPath: FileManager.default.currentDirectoryPath)
    ) {
        paths = WorkingDirectoryPaths(workingDirectory)
    }

    public func record(_ entry: Entry) { entries.append(entry) }

    /// Returns the report as a UTF-8 string. Always succeeds for the bound encodable shape.
    public func renderJSON() -> String {
        let groups = Dictionary(grouping: entries(get: \.self)) { GroupKey(file: $0.file, rule: $0.ruleID) }
        let findings = groups.map { key, members in finding(for: key, members: members) }
            .sorted { ($0.file ?? "", $0.firstLine, $0.rule) < ($1.file ?? "", $1.firstLine, $1.rule) }

        var rules: [String: RuleSummary] = [:]

        for rule in Set(findings.map(\.rule)) {
            guard let info = RuleCatalog.info(for: rule), info.key == rule else { continue }
            rules[rule] = RuleSummary(guidance: info.guidance, applicability: info.applicability)
        }
        return encodePrettyJSON(
            Report(rules: rules, findings: findings),
            fallback: #"{"findings":[],"rules":{}}"#,
            extraFormatting: .withoutEscapingSlashes
        )
    }

    /// Writes the report to standard output, terminated with a newline.
    public func flush() { writeLineToStandardOutput(renderJSON()) }

    private func finding(for key: GroupKey, members: [Entry]) -> ReportEntry {
        let sorted = members.sorted { ($0.line ?? 0, $0.column ?? 0) < ($1.line ?? 0, $1.column ?? 0) }
        let message = sorted.first?.message ?? ""
        let file = key.file.map(paths.displayPath(of:))
        let statuses = sorted.compactMap(\.status)

        let evidence = sorted.flatMap { entry in
            [ReportEvidence(
                role: .finding,
                file: nil,
                line: entry.line,
                column: entry.column,
                message: entry.message == message ? nil : entry.message,
                status: entry.status
            )]
                + entry.evidence.map { note in
                    let noteFile = note.file.map(paths.displayPath(of:))
                    return ReportEvidence(
                        role: note.role,
                        file: noteFile == file ? nil : noteFile,
                        line: note.line,
                        column: note.column,
                        message: note.message,
                        status: nil
                    )
                }
        }
        let rule = RuleCatalog.info(for: key.rule).flatMap { $0.key == key.rule ? $0 : nil }

        return ReportEntry(
            file: file,
            rule: key.rule,
            severity: sorted.map(\.severity).max { rank($0) < rank($1) } ?? "warning",
            guidance: rule?.guidance,
            message: message,
            status: statuses.isEmpty ? nil : (statuses.contains(.introduced) ? .introduced : .existing),
            evidence: evidence,
            firstLine: sorted.first?.line ?? 0
        )
    }

    private func rank(_ severity: String) -> Int {
        switch severity {
            case "error": 2
            case "warning": 1
            default: 0
        }
    }
}

// MARK: - Report shape

private struct GroupKey: Hashable {
    let file: String?
    let rule: String
}

private struct Report: Encodable {
    let rules: [String: RuleSummary]
    let findings: [ReportEntry]
}

private struct RuleSummary: Encodable {
    let guidance: GuidanceLevel
    let applicability: String
}

private struct ReportEntry: Encodable {
    let file: String?
    let rule: String
    let severity: String
    let guidance: GuidanceLevel?
    let message: String
    let status: ChangeStatus?
    let evidence: [ReportEvidence]
    /// The sort key of the entry. It is not part of the output.
    let firstLine: Int

    private enum CodingKeys: String, CodingKey {
        case file, rule, severity, guidance, message, status, evidence
    }
}

private struct ReportEvidence: Encodable {
    let role: EvidenceRole
    let file: String?
    let line: Int?
    let column: Int?
    let message: String?
    let status: ChangeStatus?
}
