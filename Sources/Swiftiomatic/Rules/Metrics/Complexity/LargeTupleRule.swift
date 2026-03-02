import SwiftSyntax

struct LargeTupleRule {
  var options = LargeTupleOptions()

  static let configuration = LargeTupleConfiguration()
}

extension LargeTupleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LargeTupleRule {
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
