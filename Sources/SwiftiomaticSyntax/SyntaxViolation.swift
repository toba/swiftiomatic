package import SwiftSyntax

/// A violation produced by `ViolationCollectingVisitor`s.
public struct SyntaxViolation: Comparable, Hashable {
  /// The correction of a violation that is basically the violation's range in the source code and a
  /// replacement for this range that would fix the violation.
  public struct Correction: Hashable {
    /// Start position of the violation range.
    public let start: AbsolutePosition
    /// End position of the violation range.
    public let end: AbsolutePosition
    /// Replacement for the violating range.
    public let replacement: String

    public init(start: AbsolutePosition, end: AbsolutePosition, replacement: String) {
      self.start = start
      self.end = end
      self.replacement = replacement
    }
  }

  /// The violation's position.
  public let position: AbsolutePosition
  /// A specific reason for the violation.
  public let reason: ViolationMessage?
  /// The violation's severity.
  public let severity: Severity?
  /// An optional correction of the violation to be used in rewriting (see ``SwiftSyntaxRule``). Can be
  /// left unset when creating a violation, especially if the rule is not correctable or provides a custom rewriter.
  public let correction: Correction?
  /// The confidence level of this violation.
  public let confidence: Confidence
  /// A suggested fix for the violation.
  public let suggestion: String?

  /// Creates a `SyntaxViolation` with a typed ``ViolationMessage``.
  ///
  /// - Parameters:
  ///   - position: The violations position in the analyzed source file.
  ///   - message: The typed message for the violation if different from the rule's description.
  ///   - severity: The severity of the violation if different from the rule's default configured severity.
  ///   - correction: An optional correction of the violation to be used in rewriting.
  ///   - confidence: The confidence level.
  ///   - suggestion: A suggested fix for the violation.
  public init(
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
  public init(
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

  public static func < (lhs: Self, rhs: Self) -> Bool {
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
  public mutating func append(_ position: AbsolutePosition) {
    append(SyntaxViolation(position: position))
  }

  /// Add a violation and the correction at the specified position using the default description and severity.
  ///
  /// - Parameters:
  ///   - position: The position for the violation to append.
  ///   - correction: An optional correction to be applied when running with `--fix`.
  public mutating func append(
    at position: AbsolutePosition, correction: SyntaxViolation.Correction? = nil,
  ) {
    append(SyntaxViolation(position: position, correction: correction))
  }

  /// Add violations for the specified positions using the default description and severity.
  ///
  /// - Parameters:
  ///   - positions: The positions for the violations to append.
  public mutating func append(contentsOf positions: [AbsolutePosition]) {
    append(contentsOf: positions.map { SyntaxViolation(position: $0) })
  }
}
