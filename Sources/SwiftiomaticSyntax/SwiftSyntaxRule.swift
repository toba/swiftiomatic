import Foundation
package import SwiftSyntax

/// A Swiftiomatic ``Rule`` backed by SwiftSyntax that does not use SourceKit requests
package protocol SwiftSyntaxRule: Rule {
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

  /// Produce a ``ViolationCollectingRewriter`` for the given file
  ///
  /// Only needed for correctable rules. Returns `nil` by default, which falls back
  /// to the visitor's collected `violationCorrections`.
  ///
  /// - Parameters:
  ///   - file: The file for which to produce the rewriter.
  /// - Returns: A ``ViolationCollectingRewriter`` for the given file, or `nil` to fall back
  ///   to the visitor's collected `violationCorrections`.
  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>?
}

extension SwiftSyntaxRule where OptionsType: SeverityBasedRuleOptions {
  package func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation {
    RuleViolation(
      ruleType: Self.self,
      severity: violation.severity ?? options.severity,
      location: Location(file: file, position: violation.position),
      message: violation.reason,
      confidence: violation.confidence,
      suggestion: violation.suggestion,
    )
  }
}

extension SwiftSyntaxRule {
  package func validate(file: SwiftSource) -> [RuleViolation] {
    guard let syntaxTree = preprocess(file: file) else {
      return []
    }

    let violations = makeVisitor(file: file)
      .walk(tree: syntaxTree, handler: \.violations)
    assert(
      violations
        .allSatisfy { $0.correction == nil || Self.isCorrectable },
      "\(Self.self) produced corrections without being correctable.",
    )
    return
      violations
      .sorted()
      .map { makeViolation(file: file, violation: $0) }
  }

  package func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation {
    RuleViolation(
      ruleType: Self.self,
      severity: violation.severity ?? .warning,
      location: Location(file: file, position: violation.position),
      message: violation.reason,
      confidence: violation.confidence,
      suggestion: violation.suggestion,
    )
  }

  package func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.syntaxTree
  }

  package func makeRewriter(file _: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    nil
  }

  /// Create a type-erased visitor for use in the lint pipeline
  package func makePipelineVisitor(file: SwiftSource) -> SyntaxVisitor & ViolationCollectingVisitorProtocol
  {
    makeVisitor(file: file)
  }

}

/// A SwiftSyntax `SyntaxRewriter` that produces absolute positions where corrections were applied
open class ViolationCollectingRewriter<Configuration: RuleOptions>: SyntaxRewriter {
  /// The rule's configuration
  public let configuration: Configuration
  /// The file from which the traversed syntax tree stems
  public let file: SwiftSource

  /// A converter of positions in the traversed source file
  public let locationConverter: SourceLocationConverter
  /// The regions in the traversed file that are disabled by a command
  public let disabledRegions: [SourceRange]

  /// The number of corrections made by the rewriter
  open var numberOfCorrections = 0

  /// Create a ``ViolationCollectingRewriter``
  ///
  /// - Parameters:
  ///   - configuration: Configuration of a rule.
  ///   - file: File from which the syntax tree stems.
  public init(configuration: Configuration, file: SwiftSource) {
    self.configuration = configuration
    self.file = file
    locationConverter = file.locationConverter
    disabledRegions = file.regions()
      .filter { $0.areRulesDisabled(ruleIDs: Configuration.Parent.allIdentifiers) }
      .compactMap { $0.toSourceRange(locationConverter: file.locationConverter) }
  }

  /// Determine whether the rule is disabled at the start position of the given syntax node
  ///
  /// - Parameters:
  ///   - node: The syntax node to check.
  /// - Returns: `true` if the rule is disabled for the node.
  open func isDisabled(atStartPositionOf node: some SyntaxProtocol) -> Bool {
    node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
  }

  open override func visitAny(_ node: Syntax) -> Syntax? {
    isDisabled(atStartPositionOf: node) ? node : nil
  }
}
