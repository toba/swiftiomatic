import Foundation
import Testing

@testable import Swiftiomatic

@Suite struct DiagnosticFormatterTests {
  private static func makeDiagnostic(
    ruleID: String = "test-rule",
    severity: Severity = .warning,
    file: String = "/path/to/File.swift",
    line: Int = 42,
    column: Int = 5,
    message: String = "Test message"
  ) -> Diagnostic {
    Diagnostic(
      ruleID: ruleID,
      source: .lint,
      severity: severity,
      confidence: .high,
      file: file,
      line: line,
      column: column,
      message: message,
      suggestion: nil,
      canAutoFix: false
    )
  }

  // MARK: - Xcode Format

  @Test func xcodeFormatMatchesXcodeExpectedPattern() {
    // Xcode parses build output lines matching: file:line:column: (warning|error): message
    let diagnostic = Self.makeDiagnostic(
      ruleID: "typed-throws",
      severity: .warning,
      file: "/Users/dev/Project/Sources/Foo.swift",
      line: 10,
      column: 3,
      message: "Function throws untyped error"
    )
    let output = DiagnosticFormatter.formatXcode([diagnostic])

    #expect(
      output
        == "/Users/dev/Project/Sources/Foo.swift:10:3: warning: [typed-throws] Function throws untyped error"
    )
  }

  @Test func xcodeFormatError() {
    let diagnostic = Self.makeDiagnostic(severity: .error, message: "Something is wrong")
    let output = DiagnosticFormatter.formatXcode([diagnostic])

    #expect(output.contains(": error: [test-rule]"))
  }

  @Test func xcodeFormatMultipleDiagnostics() {
    let diagnostics = [
      Self.makeDiagnostic(file: "A.swift", line: 1, column: 1, message: "First"),
      Self.makeDiagnostic(file: "B.swift", line: 2, column: 3, message: "Second"),
    ]
    let output = DiagnosticFormatter.formatXcode(diagnostics)
    let lines = output.split(separator: "\n")

    #expect(lines.count == 2)
    #expect(lines[0] == "A.swift:1:1: warning: [test-rule] First")
    #expect(lines[1] == "B.swift:2:3: warning: [test-rule] Second")
  }

  @Test func xcodeFormatEmptyDiagnostics() {
    let output = DiagnosticFormatter.formatXcode([])
    #expect(output.isEmpty)
  }

  @Test func xcodeFormatLineIsParsableByXcode() {
    // Xcode regex: ^(/.+?):(\d+):(\d+): (warning|error): (.+)$
    let diagnostic = Self.makeDiagnostic(
      file: "/absolute/path/File.swift",
      line: 99,
      column: 12
    )
    let output = DiagnosticFormatter.formatXcode([diagnostic])

    // Verify the output starts with file path, then line:column, then severity
    let parts = output.split(separator: ":", maxSplits: 4)
    // parts: ["", "/absolute/path/File.swift", "99", "12", " warning: [test-rule] Test message"]
    // Note: leading "/" causes the first split element to be empty when splitting on ":"
    // Actually let's just verify the whole format with a regex
    let pattern = #"^/.+:\d+:\d+: (warning|error): \[.+\] .+$"#
    #expect(output.range(of: pattern, options: .regularExpression) != nil)
  }

  // MARK: - JSON Format

  @Test func jsonFormatProducesValidJSON() throws {
    let diagnostic = Self.makeDiagnostic()
    let json = try DiagnosticFormatter.formatJSON([diagnostic])
    let data = try #require(json.data(using: .utf8))
    let decoded = try JSONDecoder().decode([Diagnostic].self, from: data)

    #expect(decoded.count == 1)
    #expect(decoded[0].ruleID == "test-rule")
    #expect(decoded[0].line == 42)
  }
}
