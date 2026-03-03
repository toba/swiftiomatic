import Foundation
import SwiftFormat
import Synchronization

/// A record of a formatting issue found by the swift-format linter
public struct FormatFinding: Sendable, Equatable {
    /// The category/rule that produced this finding
    public let category: String

    /// Human-readable description
    public let message: String

    /// Source file path
    public let filePath: String?

    /// 1-indexed line number
    public let line: Int

    /// 1-indexed column number
    public let column: Int

    /// Converts this finding into a unified ``Diagnostic`` for reporting
    public func toDiagnostic() -> Diagnostic {
        Diagnostic(
            ruleID: category,
            source: .format,
            severity: .warning,
            confidence: .high,
            file: filePath ?? "<unknown>",
            line: line,
            column: column,
            message: message,
            suggestion: nil,
            canAutoFix: true,
        )
    }
}

/// Configuration for the format engine, mapped from `.swiftiomatic.yaml`
public struct FormatEngineConfiguration: Sendable {
    /// Number of spaces per indent level (0 means use tabs)
    public var indentWidth: Int = 4

    /// Whether to indent with tabs instead of spaces
    public var useTabs: Bool = false

    /// Maximum line length before wrapping
    public var lineLength: Int = 120

    /// Maximum consecutive blank lines allowed
    public var maximumBlankLines: Int = 1

    /// Whether to put `else`/`catch` on a new line
    public var lineBreakBeforeControlFlowKeywords: Bool = false

    /// Whether to put each argument on its own line
    public var lineBreakBeforeEachArgument: Bool = false

    /// Trailing comma behavior in multiline collections
    public var trailingCommas: Bool = true

    public init() {}
}

/// A configured formatting engine that can format or lint Swift source code
///
/// Uses swift-format's Oppen-style pretty-printer for formatting and whitespace linting.
public struct FormatEngine: Sendable {
    /// The engine configuration
    public let engineConfiguration: FormatEngineConfiguration

    /// Creates an engine with the given configuration
    public init(configuration: FormatEngineConfiguration = .init()) {
        engineConfiguration = configuration
    }

    /// Formats Swift source code and returns the formatted output
    public func format(_ source: String) throws -> String {
        let formatter = SwiftFormatter(configuration: makeSwiftFormatConfiguration())
        var output = ""
        try formatter.format(
            source: source,
            assumingFileURL: nil,
            selection: .infinite,
            to: &output,
        )
        return output
    }

    /// Lints Swift source code and returns findings (formatting issues)
    public func lint(_ source: String) throws -> [FormatFinding] {
        try lint(source, filePath: nil)
    }

    /// Lints Swift source code with a file path for diagnostic output
    public func lint(_ source: String, filePath: String) throws -> [FormatFinding] {
        try lint(source, filePath: filePath as String?)
    }

    private func lint(_ source: String, filePath: String?) throws -> [FormatFinding] {
        let findings = Mutex<[FormatFinding]>([])
        let linter = SwiftLinter(configuration: makeSwiftFormatConfiguration()) { finding in
            let line = finding.location?.line ?? 1
            let column = finding.location?.column ?? 1
            findings.withLock {
                $0.append(
                    FormatFinding(
                        category: "\(finding.category)",
                        message: "\(finding.message)",
                        filePath: filePath,
                        line: line,
                        column: column,
                    ),
                )
            }
        }

        let url = URL(filePath: filePath ?? "/tmp/stdin.swift")
        try linter.lint(source: source, assumingFileURL: url)
        return findings.withLock { $0 }
    }

    /// Maps ``FormatEngineConfiguration`` to swift-format's ``SwiftFormat/Configuration``
    private func makeSwiftFormatConfiguration() -> SwiftFormat.Configuration {
        var config = SwiftFormat.Configuration()
        if engineConfiguration.useTabs {
            config.indentation = .tabs(1)
        } else {
            config.indentation = .spaces(engineConfiguration.indentWidth)
        }
        config.lineLength = engineConfiguration.lineLength
        config.maximumBlankLines = engineConfiguration.maximumBlankLines
        config.lineBreakBeforeControlFlowKeywords =
            engineConfiguration
                .lineBreakBeforeControlFlowKeywords
        config.lineBreakBeforeEachArgument = engineConfiguration.lineBreakBeforeEachArgument
        config.multiElementCollectionTrailingCommas = engineConfiguration.trailingCommas
        return config
    }
}
