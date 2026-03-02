import SwiftSyntax

/// A violation produced by `ViolationCollectingVisitor`s.
struct SyntaxViolation: Comparable, Hashable {
    /// The correction of a violation that is basically the violation's range in the source code and a
    /// replacement for this range that would fix the violation.
    struct Correction: Hashable {
        /// Start position of the violation range.
        let start: AbsolutePosition
        /// End position of the violation range.
        let end: AbsolutePosition
        /// Replacement for the violating range.
        let replacement: String
    }

    /// The violation's position.
    let position: AbsolutePosition
    /// A specific reason for the violation.
    let reason: ViolationMessage?
    /// The violation's severity.
    let severity: Severity?
    /// An optional correction of the violation to be used in rewriting (see ``SwiftSyntaxCorrectableRule``). Can be
    /// left unset when creating a violation, especially if the rule is not correctable or provides a custom rewriter.
    let correction: Correction?
    /// The confidence level of this violation.
    let confidence: Confidence
    /// A suggested fix for the violation.
    let suggestion: String?

    /// Creates a `SyntaxViolation` with a typed ``ViolationMessage``.
    ///
    /// - Parameters:
    ///   - position: The violations position in the analyzed source file.
    ///   - message: The typed message for the violation if different from the rule's description.
    ///   - severity: The severity of the violation if different from the rule's default configured severity.
    ///   - correction: An optional correction of the violation to be used in rewriting.
    ///   - confidence: The confidence level.
    ///   - suggestion: A suggested fix for the violation.
    init(
        position: AbsolutePosition,
        message: ViolationMessage?,
        severity: Severity? = nil,
        correction: Correction? = nil,
        confidence: Confidence = .high,
        suggestion: String? = nil,
    ) {
        self.position = position
        reason = message
        self.severity = severity
        self.correction = correction
        self.confidence = confidence
        self.suggestion = suggestion
    }

    /// Creates a `SyntaxViolation` with a plain string reason.
    ///
    /// Prefer the ``init(position:message:severity:correction:confidence:suggestion:)`` overload
    /// with a typed ``ViolationMessage`` for compile-time safety.
    ///
    /// - Parameters:
    ///   - position: The violations position in the analyzed source file.
    ///   - reason: The reason for the violation if different from the rule's description.
    ///   - severity: The severity of the violation if different from the rule's default configured severity.
    ///   - correction: An optional correction of the violation to be used in rewriting.
    ///   - confidence: The confidence level.
    ///   - suggestion: A suggested fix for the violation.
    init(
        position: AbsolutePosition,
        reason: String? = nil,
        severity: Severity? = nil,
        correction: Correction? = nil,
        confidence: Confidence = .high,
        suggestion: String? = nil,
    ) {
        self.position = position
        self.reason = reason.map { ViolationMessage(stringLiteral: $0) }
        self.severity = severity
        self.correction = correction
        self.confidence = confidence
        self.suggestion = suggestion
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.position < rhs.position
    }
}

/// Extension for arrays of `SyntaxViolation`s that provides the automatic conversion of
/// `AbsolutePosition`s into `SyntaxViolation`s (without a specific reason).
extension [SyntaxViolation] {
    /// Add a violation at the specified position using the default description and severity.
    ///
    /// - Parameters:
    ///   - position: The position for the violation to append.
    mutating func append(_ position: AbsolutePosition) {
        append(SyntaxViolation(position: position))
    }

    /// Add a violation and the correction at the specified position using the default description and severity.
    ///
    /// - Parameters:
    ///   - position: The position for the violation to append.
    ///   - correction: An optional correction to be applied when running with `--fix`.
    mutating func append(
        at position: AbsolutePosition, correction: SyntaxViolation.Correction? = nil,
    ) {
        append(SyntaxViolation(position: position, correction: correction))
    }

    /// Add violations for the specified positions using the default description and severity.
    ///
    /// - Parameters:
    ///   - positions: The positions for the violations to append.
    mutating func append(contentsOf positions: [AbsolutePosition]) {
        append(contentsOf: positions.map { SyntaxViolation(position: $0) })
    }
}
