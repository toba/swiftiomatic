import ConfigurationKit
import SwiftSyntax

/// Source lines should not exceed a configurable character count.
///
/// Lint-only counterpart to the `lineLength` layout setting (which targets the
/// pretty-printer's wrap point). This rule emits findings on lines that exceed
/// `warning` / `error` thresholds.
final class LineLengthLimit: LintSyntaxRule<LineLengthLimitConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let source = node.description
        var lineNumber = 0
        var index = source.startIndex
        while index < source.endIndex {
            lineNumber += 1
            let lineEnd =
                source[index...].firstIndex(of: "\n") ?? source.endIndex
            let line = source[index..<lineEnd]
            let length = line.count
            if let severity = metricSeverity(
                value: length,
                warning: ruleConfig.warning,
                error: ruleConfig.error
            ) {
                let limit = severity == .error ? ruleConfig.error : ruleConfig.warning
                let location = Finding.Location(
                    file: context.fileURL.relativePath,
                    line: lineNumber,
                    column: 1
                )
                let category = SyntaxFindingCategory(ruleType: type(of: self))
                let configured = context.severity(of: type(of: self))
                if configured.isActive {
                    context.findingEmitter.emit(
                        .lineTooLong(length: length, limit: limit),
                        category: category,
                        severity: severity,
                        location: location
                    )
                }
            }
            if lineEnd == source.endIndex { break }
            index = source.index(after: lineEnd)
        }
        return .skipChildren
    }
}

extension Finding.Message {
    fileprivate static func lineTooLong(length: Int, limit: Int) -> Finding.Message {
        "line is \(length) characters; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct LineLengthLimitConfiguration: SyntaxRuleValue {
    package var lint: Lint = .warn
    /// Lines longer than this many characters emit a warning-severity finding.
    package var warning: Int = 120
    /// Lines longer than this many characters emit an error-severity finding.
    package var error: Int = 200

    package var rewrite: Bool {
        get { false }
        set { }
    }

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .warning) { warning = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .error) { error = v }
    }

    private enum CodingKeys: String, CodingKey {
        case lint, warning, error
    }
}
