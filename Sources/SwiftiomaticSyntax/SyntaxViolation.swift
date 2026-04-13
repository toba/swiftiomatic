package import SwiftSyntax

/// A violation produced by `ViolationCollectingVisitor`s.
public struct SyntaxViolation: Comparable, Hashable {
  /// A correction that can be applied to fix a violation.
  ///
  /// Corrections come in four flavors:
  /// - ``textReplacement``: raw byte-range replacement (the original model)
  /// - ``replaceNode``: structural node replacement with smart trivia preservation
  /// - ``replaceLeadingTrivia``: trivia-only edit on the leading side of a token
  /// - ``replaceTrailingTrivia``: trivia-only edit on the trailing side of a token
  public enum Correction: Equatable {
    /// Replace the byte range `start..<end` with `replacement`.
    case textReplacement(start: AbsolutePosition, end: AbsolutePosition, replacement: String)

    /// Replace `oldNode` with `newNode`, automatically preserving matching
    /// leading/trailing trivia (mirroring swift-syntax `FixIt.Change.replace`).
    case replaceNode(oldNode: Syntax, newNode: Syntax)

    /// Replace the leading trivia on `token` with `newTrivia`.
    case replaceLeadingTrivia(token: TokenSyntax, newTrivia: Trivia)

    /// Replace the trailing trivia on `token` with `newTrivia`.
    case replaceTrailingTrivia(token: TokenSyntax, newTrivia: Trivia)

    // MARK: - Convenience initializer for the original byte-range API

    /// Creates a text-replacement correction (backward-compatible with the struct initializer).
    public init(start: AbsolutePosition, end: AbsolutePosition, replacement: String) {
      self = .textReplacement(start: start, end: end, replacement: replacement)
    }

    // MARK: - Resolved range + replacement text

    /// The byte range and replacement string that this correction resolves to.
    ///
    /// Returns `nil` when the correction is a no-op (trivia already matches).
    package var resolved: (start: AbsolutePosition, end: AbsolutePosition, replacement: String)? {
      switch self {
      case .textReplacement(let start, let end, let replacement):
        return (start, end, replacement)

      case .replaceNode(let oldNode, let newNode):
        let leadingMatch = oldNode.leadingTrivia == newNode.leadingTrivia
        let trailingMatch = oldNode.trailingTrivia == newNode.trailingTrivia
        let start = leadingMatch
          ? oldNode.positionAfterSkippingLeadingTrivia : oldNode.position
        let end = trailingMatch
          ? oldNode.endPositionBeforeTrailingTrivia : oldNode.endPosition
        var detached = newNode.detached
        if leadingMatch { detached.leadingTrivia = [] }
        if trailingMatch { detached.trailingTrivia = [] }
        return (start, end, detached.description)

      case .replaceLeadingTrivia(let token, let newTrivia):
        guard token.leadingTrivia != newTrivia else { return nil }
        return (
          token.position,
          token.positionAfterSkippingLeadingTrivia,
          newTrivia.description
        )

      case .replaceTrailingTrivia(let token, let newTrivia):
        guard token.trailingTrivia != newTrivia else { return nil }
        return (
          token.endPositionBeforeTrailingTrivia,
          token.endPosition,
          newTrivia.description
        )
      }
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

extension SyntaxViolation.Correction: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .textReplacement(let start, let end, let replacement):
      hasher.combine(0)
      hasher.combine(start)
      hasher.combine(end)
      hasher.combine(replacement)
    case .replaceNode(let oldNode, let newNode):
      hasher.combine(1)
      hasher.combine(oldNode)
      hasher.combine(newNode)
    case .replaceLeadingTrivia(let token, _):
      hasher.combine(2)
      hasher.combine(token)
    case .replaceTrailingTrivia(let token, _):
      hasher.combine(3)
      hasher.combine(token)
    }
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
