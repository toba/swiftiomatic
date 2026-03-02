import SwiftSyntax

/// A Swiftiomatic ``Rule`` backed by SwiftSyntax that does not use SourceKit requests
protocol SwiftSyntaxRule: SyntaxOnlyRule {
  /// Produce a ``ViolationCollectingVisitor`` for the given file
  ///
  /// - Parameters:
  ///   - file: The file for which to produce the visitor.
  /// - Returns: A ``ViolationCollectingVisitor`` for the given file.
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType>

  /// Produce a ``RuleViolation`` for the given file and syntax violation
  ///
  /// - Parameters:
  ///   - file: The file for which to produce the violation.
  ///   - violation: A violation in the file.
  /// - Returns: A violation for the given file and absolute position.
  func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation

  /// Pre-process the syntax tree before checking for violations
  ///
  /// Override this to fold operators or skip validation in certain files.
  /// By default returns the file's `syntaxTree`.
  ///
  /// - Parameters:
  ///   - file: The file to run pre-processing on.
  /// - Returns: The tree that will be used to check for violations, or `nil` to produce no violations.
  func preprocess(file: SwiftSource) -> SourceFileSyntax?
}

extension SwiftSyntaxRule where OptionsType: SeverityBasedRuleOptions {
  func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation {
    RuleViolation(
      ruleType: Self.self,
      severity: violation.severity ?? options.severity,
      location: Location(file: file, position: violation.position),
      reason: violation.reason,
      confidence: violation.confidence,
      suggestion: violation.suggestion,
    )
  }
}

extension SwiftSyntaxRule {
  @inlinable
  func validate(file: SwiftSource) -> [RuleViolation] {
    guard let syntaxTree = preprocess(file: file) else {
      return []
    }

    let violations = makeVisitor(file: file)
      .walk(tree: syntaxTree, handler: \.violations)
    assert(
      violations
        .allSatisfy { $0.correction == nil || self is any SwiftSyntaxCorrectableRule },
      "\(Self.self) produced corrections without being correctable.",
    )
    return
      violations
      .sorted()
      .map { makeViolation(file: file, violation: $0) }
  }

  func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation {
    guard let severity = violation.severity else {
      // This error will only be thrown in tests. It cannot come up at runtime.
      Console.fatalError(
        """
        A severity must be provided. Either define it in the violation or make the rule configuration \
        conform to `SeverityBasedRuleOptions` to take the default.
        """,
      )
    }
    return RuleViolation(
      ruleType: Self.self,
      severity: severity,
      location: Location(file: file, position: violation.position),
      reason: violation.reason,
      confidence: violation.confidence,
      suggestion: violation.suggestion,
    )
  }

  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.syntaxTree
  }
}
