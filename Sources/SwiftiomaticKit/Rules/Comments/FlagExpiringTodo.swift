import Foundation
import SwiftSyntax
import ConfigurationKit

/// `TODO` and `FIXME` comments with a bracketed date should be resolved by that date.
///
/// A trailing date in a configurable format (default `[MM/dd/yyyy]` ) is parsed and compared to the
/// current date. Comments approaching, past, or incorrectly formatted dates emit findings at
/// independently-configured severities.
///
/// Lint: If a dated TODO/FIXME is approaching expiry, expired, or has a malformed date, a lint
/// finding is raised.
final class FlagExpiringTodo: LintSyntaxRule<ExpiringTodoConfiguration>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .comments }

    private enum ExpiryLevel { case approaching, expired, badFormatting }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        scan(
            trivia: token.leadingTrivia,
            baseOffset: token.position.utf8Offset
        )
        scan(
            trivia: token.trailingTrivia,
            baseOffset: token.endPositionBeforeTrailingTrivia.utf8Offset
        )
        return .visitChildren
    }

    private func scan(trivia: Trivia, baseOffset: Int) {
        let config = ruleConfig
        guard let regex = Self.regex(for: config) else { return }

        var pieceOffset = baseOffset

        for piece in trivia {
            defer { pieceOffset += piece.sourceLength.utf8Length }

            let text: String

            switch piece {
                case let .lineComment(t),
                     let .blockComment(t),
                     let .docLineComment(t),
                     let .docBlockComment(t):
                    text = t
                default: continue
            }
            let nsText = text as NSString
            let range = NSRange(location: 0, length: nsText.length)

            for match in regex.matches(in: text, options: [], range: range)
            where match.numberOfRanges > 1 {
                let dateRange = match.range(at: 1)
                guard dateRange.location != NSNotFound else { continue }

                let dateString = nsText.substring(with: dateRange)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard let level = expiryLevel(for: dateString, config: config),
                      let severity = severity(for: level, config: config) else { continue }

                let absolute = AbsolutePosition(utf8Offset: pieceOffset + dateRange.location)
                let location = Finding.Location(
                    context.sourceLocationConverter.location(
                        for: absolute
                    ))
                let category = SyntaxFindingCategory(ruleType: type(of: self))
                let configured = context.severity(of: type(of: self))
                guard configured.isActive else { return }

                context.findingEmitter.emit(
                    message(for: level),
                    category: category,
                    severity: severity,
                    location: location
                )
            }
        }
    }

    private func expiryLevel(
        for dateString: String,
        config: ExpiringTodoConfiguration
    ) -> ExpiryLevel? {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.dateFormat = config.dateFormat
        guard let expiryDate = formatter.date(from: dateString) else { return .badFormatting }
        let calendar = Calendar.current
        let today = Date()

        if calendar.compare(today, to: expiryDate, toGranularity: .day) != .orderedAscending {
            return .expired
        }
        guard let approachingDate = calendar.date(
            byAdding: .day,
            value: -config.approachingExpiryThreshold,
            to: expiryDate
        ) else { return nil }

        return calendar.compare(
            today, to: approachingDate, toGranularity: .day) != .orderedAscending
            ? .approaching
            : nil
    }

    private func severity(
        for level: ExpiryLevel,
        config: ExpiringTodoConfiguration
    ) -> Lint? {
        let value: Lint

        switch level {
            case .approaching: value = config.approachingExpirySeverity
            case .expired: value = config.expiredSeverity
            case .badFormatting: value = config.badFormattingSeverity
        }
        return value.isActive ? value : nil
    }

    private func message(for level: ExpiryLevel) -> Finding.Message {
        switch level {
            case .approaching: .todoApproachingExpiry
            case .expired: .todoExpired
            case .badFormatting: .todoBadFormatting
        }
    }

    private static func regex(for config: ExpiringTodoConfiguration) -> NSRegularExpression? {
        let opening = NSRegularExpression.escapedPattern(for: config.dateDelimitersOpening)
        let closing = NSRegularExpression.escapedPattern(for: config.dateDelimitersClosing)
        let separator = NSRegularExpression.escapedPattern(for: config.dateSeparator)
        let pattern = """
            \\b(?:TODO|FIXME)(?::|\\b)(?:(?!\\b(?:TODO|FIXME)(?::|\\b)).)*?\
            \(opening)(\\d{1,4}\(separator)\\d{1,4}\(separator)\\d{1,4})\(closing)
            """
        return try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
    }
}

fileprivate extension Finding.Message {
    static let todoApproachingExpiry: Finding.Message =
        "TODO/FIXME is approaching its expiry and should be resolved soon"
    static let todoExpired: Finding.Message = "TODO/FIXME has expired and must be resolved"
    static let todoBadFormatting: Finding.Message = "expiring TODO/FIXME is incorrectly formatted"
}

// MARK: - Configuration

package struct ExpiringTodoConfiguration: SyntaxRuleValue {
    package var rewrite = false
    package var lint: Lint = .warn
    /// `DateFormatter` pattern used to parse the expiry date out of the comment.
    package var dateFormat = "MM/dd/yyyy"
    /// Opening delimiter that introduces the date inside the TODO comment.
    package var dateDelimitersOpening = "["
    /// Closing delimiter that terminates the date inside the TODO comment.
    package var dateDelimitersClosing = "]"
    /// Separator between date components.
    package var dateSeparator = "/"
    /// Days before expiry at which the TODO starts being reported as approaching its deadline.
    package var approachingExpiryThreshold: Int = 15
    /// Severity reported for TODOs whose expiry is within `approachingExpiryThreshold` days.
    package var approachingExpirySeverity: Lint = .warn
    /// Severity reported for TODOs whose expiry date has already passed.
    package var expiredSeverity: Lint = .error
    /// Severity reported for TODOs whose date couldn't be parsed using `dateFormat` and the
    /// configured delimiters.
    package var badFormattingSeverity: Lint = .warn

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Bool.self, forKey: .rewrite) { rewrite = v }
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent(String.self, forKey: .dateFormat) { dateFormat = v }
        if let v = try c.decodeIfPresent(String.self, forKey: .dateDelimitersOpening) {
            dateDelimitersOpening = v
        }
        if let v = try c.decodeIfPresent(String.self, forKey: .dateDelimitersClosing) {
            dateDelimitersClosing = v
        }
        if let v = try c.decodeIfPresent(String.self, forKey: .dateSeparator) { dateSeparator = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .approachingExpiryThreshold) {
            approachingExpiryThreshold = v
        }
        if let v = try c.decodeIfPresent(Lint.self, forKey: .approachingExpirySeverity) {
            approachingExpirySeverity = v
        }
        if let v = try c.decodeIfPresent(Lint.self, forKey: .expiredSeverity) {
            expiredSeverity = v
        }
        if let v = try c.decodeIfPresent(Lint.self, forKey: .badFormattingSeverity) {
            badFormattingSeverity = v
        }
    }

    private enum CodingKeys: String, CodingKey {
        case rewrite, lint, dateFormat, dateDelimitersOpening, dateDelimitersClosing
        case dateSeparator, approachingExpiryThreshold, approachingExpirySeverity
        case expiredSeverity, badFormattingSeverity
    }
}
