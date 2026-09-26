import Foundation
import Testing
@testable import SwiftiomaticKit

@Suite("SARIFLintReporter")
struct SARIFLintReporterTests {
    private let workingDirectory = URL(fileURLWithPath: "/work/project", isDirectory: true)

    private func makeReporter() -> SARIFLintReporter {
        .init(toolVersion: "1.2.3", workingDirectory: workingDirectory)
    }

    private func render(
        _ reporter: SARIFLintReporter,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> [String: Any] {
        let data = Data(reporter.renderJSON().utf8)
        return try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any],
            sourceLocation: sourceLocation
        )
    }

    private func onlyRun(
        _ log: [String: Any],
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> [String: Any] {
        let runs = try #require(log["runs"] as? [[String: Any]], sourceLocation: sourceLocation)
        #expect(runs.count == 1, sourceLocation: sourceLocation)
        return try #require(runs.first, sourceLocation: sourceLocation)
    }

    private func firstPhysicalLocation(
        _ run: [String: Any],
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> [String: Any] {
        let result = try #require(
            (run["results"] as? [[String: Any]])?.first,
            sourceLocation: sourceLocation
        )
        let locations = try #require(
            result["locations"] as? [[String: Any]],
            sourceLocation: sourceLocation
        )
        return try #require(
            locations.first?["physicalLocation"] as? [String: Any],
            sourceLocation: sourceLocation
        )
    }

    @Test func emptyLogHasOneRunWithNoResults() throws {
        let log = try render(makeReporter())
        #expect(log["version"] as? String == "2.1.0")
        #expect(log["$schema"] as? String == "https://json.schemastore.org/sarif-2.1.0.json")

        let run = try onlyRun(log)
        #expect((run["results"] as? [Any])?.isEmpty == true)

        let driver = try #require(
            (run["tool"] as? [String: Any])?["driver"] as? [String: Any]
        )
        #expect(driver["name"] as? String == "sm")
        #expect(driver["version"] as? String == "1.2.3")
        #expect((driver["rules"] as? [Any])?.isEmpty == true)
    }

    @Test func findingMapsToResult() throws {
        let reporter = makeReporter()
        reporter.record(
            SARIFLintReporter.Entry(
                file: "/work/project/Sources/Foo.swift",
                line: 12,
                column: 5,
                level: .warning,
                ruleID: "requireCamelCaseIdentifiers",
                message: "rename the function 'Foo' using lowerCamelCase"
            )
        )

        let run = try onlyRun(try render(reporter))
        let results = try #require(run["results"] as? [[String: Any]])
        #expect(results.count == 1)

        let result = results[0]
        #expect(result["ruleId"] as? String == "requireCamelCaseIdentifiers")
        #expect(result["ruleIndex"] as? Int == 0)
        #expect(result["level"] as? String == "warning")
        #expect(
            (result["message"] as? [String: Any])?["text"] as? String
                == "rename the function 'Foo' using lowerCamelCase"
        )

        let physical = try firstPhysicalLocation(run)
        let artifact = try #require(physical["artifactLocation"] as? [String: Any])
        #expect(artifact["uri"] as? String == "Sources/Foo.swift")
        #expect(artifact["uriBaseId"] as? String == "%SRCROOT%")

        let region = try #require(physical["region"] as? [String: Any])
        #expect(region["startLine"] as? Int == 12)
        #expect(region["startColumn"] as? Int == 5)

        let baseIDs = try #require(run["originalUriBaseIds"] as? [String: Any])
        let root = try #require(baseIDs["%SRCROOT%"] as? [String: Any])
        #expect(root["uri"] as? String == "file:///work/project/")
    }

    @Test func parserDiagnosticKeepsItsFixedRuleID() throws {
        let reporter = makeReporter()
        reporter.record(
            SARIFLintReporter.Entry(
                file: "/work/project/Bad.swift",
                line: 1,
                column: 9,
                level: .error,
                ruleID: SARIFLintReporter.parserRuleID,
                message: "expected expression"
            )
        )

        let run = try onlyRun(try render(reporter))
        let result = try #require((run["results"] as? [[String: Any]])?.first)
        #expect(result["ruleId"] as? String == "parser")
        #expect(result["level"] as? String == "error")
    }

    @Test func rulesListEachFiredRuleOnce() throws {
        let reporter = makeReporter()
        for (rule, line) in [("b", 1), ("a", 2), ("b", 3)] {
            reporter.record(
                SARIFLintReporter.Entry(
                    file: "/work/project/A.swift", line: line, column: 1,
                    level: .warning, ruleID: rule, message: "m"
                )
            )
        }

        let run = try onlyRun(try render(reporter))
        let driver = try #require(
            (run["tool"] as? [String: Any])?["driver"] as? [String: Any]
        )
        let rules = try #require(driver["rules"] as? [[String: Any]])
        #expect(rules.compactMap { $0["id"] as? String } == ["a", "b"])

        let results = try #require(run["results"] as? [[String: Any]])
        #expect(results.map { $0["ruleIndex"] as? Int } == [1, 0, 1])
    }

    @Test func fileOutsideWorkingDirectoryUsesAbsoluteURI() throws {
        let reporter = makeReporter()
        reporter.record(
            SARIFLintReporter.Entry(
                file: "/elsewhere/My File.swift", line: 3, column: 2,
                level: .warning, ruleID: "r", message: "m"
            )
        )

        let physical = try firstPhysicalLocation(try onlyRun(try render(reporter)))
        let artifact = try #require(physical["artifactLocation"] as? [String: Any])
        #expect(artifact["uri"] as? String == "file:///elsewhere/My%20File.swift")
        #expect(artifact["uriBaseId"] == nil)
    }

    @Test func siblingDirectoryWithSharedPrefixIsNotRelative() throws {
        let reporter = makeReporter()
        reporter.record(
            SARIFLintReporter.Entry(
                file: "/work/project-other/A.swift", line: 1, column: 1,
                level: .warning, ruleID: "r", message: "m"
            )
        )

        let physical = try firstPhysicalLocation(try onlyRun(try render(reporter)))
        let artifact = try #require(physical["artifactLocation"] as? [String: Any])
        #expect(artifact["uri"] as? String == "file:///work/project-other/A.swift")
    }

    @Test func missingLocationOmitsLocations() throws {
        let reporter = makeReporter()
        reporter.record(
            SARIFLintReporter.Entry(
                file: nil, line: nil, column: nil,
                level: .error, ruleID: SARIFLintReporter.toolRuleID, message: "io error"
            )
        )

        let run = try onlyRun(try render(reporter))
        let result = try #require((run["results"] as? [[String: Any]])?.first)
        #expect(result["ruleId"] as? String == "tool")
        #expect((result["locations"] as? [Any])?.isEmpty ?? true)
    }

    @Test func evidenceMapsToRelatedLocationsWithRole() throws {
        let reporter = makeReporter()
        reporter.record(
            SARIFLintReporter.Entry(
                file: "/work/project/A.swift", line: 5, column: 1,
                level: .warning, ruleID: "noNestedWithLock", message: "m",
                evidence: [
                    LintEvidence(
                        role: .owner, file: "/work/project/A.swift", line: 2, column: 3,
                        message: "outer lock"
                    )
                ]
            )
        )

        let result = try #require(
            (try onlyRun(try render(reporter))["results"] as? [[String: Any]])?.first
        )
        let related = try #require(result["relatedLocations"] as? [[String: Any]])
        #expect(related.count == 1)
        #expect(related[0]["id"] as? Int == 0)
        #expect((related[0]["message"] as? [String: Any])?["text"] as? String == "outer lock")
        #expect((related[0]["properties"] as? [String: Any])?["role"] as? String == "owner")
        let region = (related[0]["physicalLocation"] as? [String: Any])?["region"] as? [String: Any]
        #expect(region?["startLine"] as? Int == 2)
    }

    @Test func changeStatusMapsToBaselineState() throws {
        let reporter = makeReporter()
        for (line, status) in [(1, ChangeStatus.introduced), (2, .existing)] {
            reporter.record(
                SARIFLintReporter.Entry(
                    file: "/work/project/A.swift", line: line, column: 1,
                    level: .warning, ruleID: "r", message: "m", status: status
                )
            )
        }
        reporter.record(
            SARIFLintReporter.Entry(
                file: "/work/project/A.swift", line: 3, column: 1,
                level: .warning, ruleID: "r", message: "m"
            )
        )

        let results = try #require(try onlyRun(try render(reporter))["results"] as? [[String: Any]])
        #expect(results.map { $0["baselineState"] as? String } == ["new", "unchanged", nil])
    }

    @Test func knownRuleDescriptorCarriesApplicabilityAndGuidance() throws {
        let reporter = makeReporter()
        reporter.record(
            SARIFLintReporter.Entry(
                file: "/work/project/A.swift", line: 1, column: 1,
                level: .warning, ruleID: "noNestedWithLock", message: "m"
            )
        )

        let driver = try #require(
            (try onlyRun(try render(reporter))["tool"] as? [String: Any])?["driver"]
                as? [String: Any]
        )
        let rule = try #require((driver["rules"] as? [[String: Any]])?.first)
        let short = try #require(rule["shortDescription"] as? [String: Any])
        #expect((short["text"] as? String)?.hasPrefix("Lint nested") == true)
        #expect((rule["properties"] as? [String: Any])?["guidance"] as? String == "MUST")
    }
}
