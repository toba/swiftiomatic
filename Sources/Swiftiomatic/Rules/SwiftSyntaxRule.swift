import SwiftSyntax

/// A Swiftiomatic Rule backed by SwiftSyntax that does not use SourceKit requests.
protocol SwiftSyntaxRule: SyntaxOnlyRule {
  /// Produce a `ViolationCollectingVisitor` for the given file.
  ///
  /// - parameter file: The file for which to produce the visitor.
  ///
  /// - returns: A `ViolationCollectingVisitor` for the given file.
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType>

  /// Produce a violation for the given file and absolute position.
  ///
  /// - parameter file:      The file for which to produce the violation.
  /// - parameter violation: A violation in the file.
  ///
  /// - returns: A violation for the given file and absolute position.
  func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation

  /// Gives a chance for the rule to do some pre-processing on the syntax tree.
  /// One typical example is using `SwiftOperators` to "fold" the tree, resolving operators precedence.
  /// This can also be used to skip validation in a given file.
  /// By default, it just returns the file's `syntaxTree`.
  ///
  /// - parameter file: The file to run pre-processing on.
  ///
  /// - returns: The tree that will be used to check for violations. If `nil`, this rule will return no violations.
  func preprocess(file: SwiftSource) -> SourceFileSyntax?
}

extension SwiftSyntaxRule where ConfigurationType: SeverityBasedRuleConfiguration {
  func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation {
    RuleViolation(
      ruleDescription: Self.description,
      severity: violation.severity ?? configuration.severity,
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
      queuedFatalError(
        """
        A severity must be provided. Either define it in the violation or make the rule configuration \
        conform to `SeverityBasedRuleConfiguration` to take the default.
        """,
      )
    }
    return RuleViolation(
      ruleDescription: Self.description,
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
