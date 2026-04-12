package import SwiftSyntax

/// A rule configuration that defines warning and error thresholds for line-count violations
public protocol SeverityLevelsBasedRuleOptions<Parent>: RuleOptions {
  /// The threshold for a violation to be a warning
  var warningThreshold: Int { get }
  /// The threshold for a violation to be an error, or `nil` if no error threshold is set
  var errorThreshold: Int? { get }
}

/// Collects violations for code blocks that exceed a configured line-count threshold
///
/// Line counts exclude comments and whitespace. Subclasses call
/// ``registerViolations(leftBrace:rightBrace:violationNode:objectName:)`` from
/// their `visitPost` overrides.
open class BodyLengthVisitor<
  LevelConfig: SeverityLevelsBasedRuleOptions,
>: ViolationCollectingVisitor<
  LevelConfig,
>
{
  @inlinable
  public override init(configuration: LevelConfig, file: SwiftSource) {
    super.init(configuration: configuration, file: file)
  }

  /// Registers a violation if a body exceeds the configured line count.
  ///
  /// - Parameters:
  ///   - leftBrace: The left brace token of the body.
  ///   - rightBrace: The right brace token of the body.
  ///   - violationNode: The syntax node where the violation is to be reported.
  ///   - objectName: The name of the object (e.g., "Function", "Closure") used in the violation message.
  open func registerViolations(
    leftBrace: TokenSyntax,
    rightBrace: TokenSyntax,
    violationNode: some SyntaxProtocol,
    objectName: String,
  ) {
    let leftBracePosition = leftBrace.positionAfterSkippingLeadingTrivia
    let leftBraceLine = locationConverter.location(for: leftBracePosition).line
    let rightBracePosition = rightBrace.positionAfterSkippingLeadingTrivia
    let rightBraceLine = locationConverter.location(for: rightBracePosition).line
    let lineCount = file.bodyLineCountIgnoringCommentsAndWhitespace(
      leftBraceLine: leftBraceLine,
      rightBraceLine: rightBraceLine,
    )
    let severity: Severity
    let upperBound: Int
    if let error = configuration.errorThreshold, lineCount > error {
      severity = .error
      upperBound = error
    } else if lineCount > configuration.warningThreshold {
      severity = .warning
      upperBound = configuration.warningThreshold
    } else {
      return
    }

    violations.append(
      .init(
        position: violationNode.positionAfterSkippingLeadingTrivia,
        reason: """
          \(objectName) body should span \(
                    upperBound
                ) lines or less excluding comments and whitespace: \
          currently spans \(lineCount) lines
          """,
        severity: severity,
      ),
    )
  }
}
