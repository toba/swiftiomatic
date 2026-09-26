import Foundation
import Testing
@testable import SwiftiomaticKit

@Suite("AgentLintReporter")
struct AgentLintReporterTests {
    private let workingDirectory = URL(fileURLWithPath: "/work/project", isDirectory: true)

    private func makeReporter() -> AgentLintReporter { .init(workingDirectory: workingDirectory) }

    private func entry(
        file: String? = "/work/project/Sources/A.swift",
        line: Int? = 1,
        column: Int? = 1,
        severity: String = "warning",
        rule: String = "dropBacktickedSelf",
        message: String = "remove backticks",
        status: ChangeStatus? = nil,
        evidence: [LintEvidence] = []
    ) -> AgentLintReporter.Entry {
        .init(
            file: file, line: line, column: column, severity: severity, ruleID: rule,
            message: message, status: status, evidence: evidence
        )
    }

    private func render(
        _ reporter: AgentLintReporter,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> (rules: [String: [String: Any]], findings: [[String: Any]]) {
        let object = try #require(
            try JSONSerialization.jsonObject(with: Data(reporter.renderJSON().utf8))
                as? [String: Any],
            sourceLocation: sourceLocation
        )
        return (
            try #require(object["rules"] as? [String: [String: Any]], sourceLocation: sourceLocation),
            try #require(object["findings"] as? [[String: Any]], sourceLocation: sourceLocation)
        )
    }

    @Test func emptyReportHasNoRulesAndNoFindings() throws {
        let (rules, findings) = try render(makeReporter())
        #expect(rules.isEmpty)
        #expect(findings.isEmpty)
    }

    @Test func findingsOfOneRuleInOneFileShareOneEntry() throws {
        let reporter = makeReporter()
        reporter.record(entry(line: 9, column: 3))
        reporter.record(entry(line: 2, column: 5))
        reporter.record(entry(file: "/work/project/Sources/B.swift", line: 4))

        let (_, findings) = try render(reporter)
        #expect(findings.count == 2)

        let first = findings[0]
        #expect(first["file"] as? String == "Sources/A.swift")
        #expect(first["rule"] as? String == "dropBacktickedSelf")
        #expect(first["message"] as? String == "remove backticks")
        #expect(first["guidance"] as? String == "SHOULD")

        let evidence = try #require(first["evidence"] as? [[String: Any]])
        #expect(evidence.map { $0["line"] as? Int } == [2, 9])
        #expect(evidence.allSatisfy { $0["role"] as? String == "finding" })
        #expect(evidence.allSatisfy { $0["message"] == nil })
        #expect(evidence.allSatisfy { $0["file"] == nil })

        #expect(findings[1]["file"] as? String == "Sources/B.swift")
    }

    @Test func evidenceKeepsMessageThatDiffersFromEntryMessage() throws {
        let reporter = makeReporter()
        reporter.record(entry(line: 1, message: "first"))
        reporter.record(entry(line: 2, message: "second"))

        let evidence = try #require(try render(reporter).findings[0]["evidence"] as? [[String: Any]])
        #expect(evidence[0]["message"] == nil)
        #expect(evidence[1]["message"] as? String == "second")
    }

    @Test func notesBecomeRoleTaggedEvidenceAfterTheirFinding() throws {
        let reporter = makeReporter()
        reporter.record(entry(
            line: 3,
            evidence: [
                LintEvidence(role: .owner, file: "/work/project/Sources/A.swift", line: 1, column: 1, message: "declared here"),
                LintEvidence(role: .input, file: "/work/project/Sources/C.swift", line: 8, column: 2, message: "read here"),
            ]
        ))

        let evidence = try #require(try render(reporter).findings[0]["evidence"] as? [[String: Any]])
        #expect(evidence.map { $0["role"] as? String } == ["finding", "owner", "input"])
        #expect(evidence[1]["message"] as? String == "declared here")
        #expect(evidence[1]["file"] == nil)
        #expect(evidence[2]["file"] as? String == "Sources/C.swift")
    }

    @Test func rulesMapCarriesGuidanceAndApplicabilityOnce() throws {
        let reporter = makeReporter()
        reporter.record(entry(file: "/work/project/A.swift"))
        reporter.record(entry(file: "/work/project/B.swift"))
        reporter.record(entry(rule: "parser", message: "expected expression"))

        let (rules, findings) = try render(reporter)
        #expect(rules.keys.sorted() == ["dropBacktickedSelf"])
        #expect(rules["dropBacktickedSelf"]?["guidance"] as? String == "SHOULD")
        #expect(
            rules["dropBacktickedSelf"]?["applicability"] as? String
                == "Remove backticks around `self` in optional unwrap expressions."
        )

        let parser = try #require(findings.first { $0["rule"] as? String == "parser" })
        #expect(parser["guidance"] == nil)
    }

    @Test func errorSeverityWinsInAGroup() throws {
        let reporter = makeReporter()
        reporter.record(entry(line: 1, severity: "warning"))
        reporter.record(entry(line: 2, severity: "error"))

        #expect(try render(reporter).findings[0]["severity"] as? String == "error")
    }

    @Test func statusIsIntroducedWhenAnyFindingIsIntroduced() throws {
        let reporter = makeReporter()
        reporter.record(entry(line: 1, status: .existing))
        reporter.record(entry(line: 2, status: .introduced))
        reporter.record(entry(file: "/work/project/Sources/B.swift", status: .existing))

        let findings = try render(reporter).findings
        #expect(findings[0]["status"] as? String == "introduced")
        let evidence = try #require(findings[0]["evidence"] as? [[String: Any]])
        #expect(evidence.map { $0["status"] as? String } == ["existing", "introduced"])
        #expect(findings[1]["status"] as? String == "existing")
    }

    @Test func statusIsAbsentWithoutChangedLines() throws {
        let reporter = makeReporter()
        reporter.record(entry())

        let finding = try render(reporter).findings[0]
        #expect(finding["status"] == nil)
    }

    @Test func outputCarriesNoURIs() throws {
        let reporter = makeReporter()
        reporter.record(entry(file: "/elsewhere/A.swift"))

        let json = reporter.renderJSON()
        #expect(!json.contains("://"))
        #expect(try render(reporter).findings[0]["file"] as? String == "/elsewhere/A.swift")
    }
}
