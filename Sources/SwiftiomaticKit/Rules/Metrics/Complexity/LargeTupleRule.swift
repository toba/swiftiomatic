import SwiftiomaticSyntax

struct LargeTupleRule: SwiftSyntaxRule {
  static let id = "large_tuple"
  static let name = "Large Tuple"
  static let summary = "Tuples shouldn't have too many members. Create a custom type instead."

  var options = LargeTupleOptions()

  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TupleTypeSyntax) {
      if configuration.ignoreRegex, node.isInsideRegexType {
        return
      }

      let memberCount = node.elements.count
      for parameter in configuration.severityConfiguration.params
      where memberCount > parameter.value {
        violations.append(
          .init(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "Tuples should have at most \(configuration.severityConfiguration.warning) members",
            severity: parameter.severity,
          ),
        )
        return
      }
    }
  }
}

// MARK: - Support

extension TupleTypeSyntax {
  fileprivate var isInsideRegexType: Bool {
    var current: Syntax? = Syntax(self)

    // Skip OptionalType wrapper if present (for Regex<(A, B)?>)
    if current?.parent?.is(OptionalTypeSyntax.self) == true {
      current = current?.parent
    }

    guard let genericArgument = current?.parent?.as(GenericArgumentSyntax.self),
      let genericArgumentList = genericArgument.parent?.as(GenericArgumentListSyntax.self),
      let genericArgumentClause = genericArgumentList.parent?
        .as(GenericArgumentClauseSyntax.self),
      let identifierType = genericArgumentClause.parent?.as(IdentifierTypeSyntax.self),
      identifierType.name.text == "Regex"
    else {
      return false
    }
    return true
  }
}

struct LargeTupleOptions: RuleOptions {
  typealias Parent = LargeTupleRule

  @OptionElement(isInline: true)
  var severityConfiguration = SeverityLevelsConfiguration<Parent>(
    warning: 2,
    error: 3,
  )
  @OptionElement(key: "ignore_regex")
  private(set) var ignoreRegex = false

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue
      where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier)
    {
      // Acceptable — severity is optional.
    }
    if let value = configuration[$ignoreRegex.key] {
      try ignoreRegex.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
