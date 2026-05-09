import Foundation
import Testing
@testable import SwiftiomaticKit

@Suite("JSONLintReporter")
struct JSONLintReporterTests {
    @Test func emptyReportEncodesAsEmptyArray() {
        let reporter = JSONLintReporter()
        let output = reporter.renderJSON()
        let parsed = try? JSONSerialization.jsonObject(with: Data(output.utf8))
        #expect(parsed as? [Any] != nil)
        #expect((parsed as? [Any])?.isEmpty == true)
    }

    @Test func entryShape() throws {
        let reporter = JSONLintReporter()
        reporter.record(
            JSONLintReporter.Entry(
                file: "/abs/Foo.swift",
                line: 12,
                column: 5,
                severity: "warning",
                rule: "requireCamelCaseIdentifiers",
                message: "rename the function 'Foo' using lowerCamelCase"
            )
        )

        let data = Data(reporter.renderJSON().utf8)
        let array = try #require(
            try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        )
        #expect(array.count == 1)
        let entry = array[0]
        #expect(entry["file"] as? String == "/abs/Foo.swift")
        #expect(entry["line"] as? Int == 12)
        #expect(entry["column"] as? Int == 5)
        #expect(entry["severity"] as? String == "warning")
        #expect(entry["rule"] as? String == "requireCamelCaseIdentifiers")
        #expect(
            entry["message"] as? String == "rename the function 'Foo' using lowerCamelCase"
        )
    }

    @Test func nilLocationFieldsEncodeAsNull() throws {
        let reporter = JSONLintReporter()
        reporter.record(
            JSONLintReporter.Entry(
                file: nil,
                line: nil,
                column: nil,
                severity: "error",
                rule: nil,
                message: "io error"
            )
        )

        let data = Data(reporter.renderJSON().utf8)
        let array = try #require(
            try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        )
        let entry = array[0]
        #expect(entry["file"] is NSNull)
        #expect(entry["line"] is NSNull)
        #expect(entry["rule"] is NSNull)
        #expect(entry["severity"] as? String == "error")
    }
}

@Suite("JSONFormatReporter")
struct JSONFormatReporterTests {
    @Test func emptyReportHasAllThreeBuckets() throws {
        let reporter = JSONFormatReporter()
        let data = Data(reporter.renderJSON().utf8)
        let object = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect((object["changed"] as? [Any])?.isEmpty == true)
        #expect((object["unchanged"] as? [Any])?.isEmpty == true)
        #expect((object["skipped"] as? [Any])?.isEmpty == true)
    }

    @Test func snakeCasedChangedEntry() throws {
        let reporter = JSONFormatReporter()
        reporter.recordChanged(file: "/abs/A.swift", bytesBefore: 21, bytesAfter: 24)
        reporter.recordUnchanged(file: "/abs/B.swift")
        reporter.recordSkipped(file: "/abs/C.swift", reason: "unparsable")

        let data = Data(reporter.renderJSON().utf8)
        let object = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        let changed = try #require(object["changed"] as? [[String: Any]])
        #expect(changed.count == 1)
        #expect(changed[0]["file"] as? String == "/abs/A.swift")
        #expect(changed[0]["bytes_before"] as? Int == 21)
        #expect(changed[0]["bytes_after"] as? Int == 24)

        let unchanged = try #require(object["unchanged"] as? [String])
        #expect(unchanged == ["/abs/B.swift"])

        let skipped = try #require(object["skipped"] as? [[String: Any]])
        #expect(skipped[0]["file"] as? String == "/abs/C.swift")
        #expect(skipped[0]["reason"] as? String == "unparsable")
    }
}
