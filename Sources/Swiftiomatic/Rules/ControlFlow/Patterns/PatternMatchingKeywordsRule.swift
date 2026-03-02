import SwiftSyntax

struct PatternMatchingKeywordsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PatternMatchingKeywordsConfiguration()

  private static func wrapInSwitch(_ example: Example) -> Example {
    example.with(
      code: """
        switch foo {
            \(example.code): break
        }
        """,
    )
  }
}

extension PatternMatchingKeywordsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PatternMatchingKeywordsRule {}

extension PatternMatchingKeywordsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseItemSyntax) {
      let localViolations = TupleVisitor(configuration: configuration, file: file)
        .walk(tree: node.pattern, handler: \.violations)
      violations.append(contentsOf: localViolations)
    }
  }
}

private final class TupleVisitor<Configuration: RuleOptions>: ViolationCollectingVisitor<
  Configuration,
>
{
  override func visitPost(_ node: LabeledExprListSyntax) {
    let list = node.flatteningEnumPatterns().map(\.expression.categorized)
    if list.contains(where: \.isReference) {
      return
    }
    let specifiers = list.compactMap {
      if case .binding(let specifier) = $0 { specifier } else { nil }
    }
    if specifiers.count > 1,
      specifiers.allSatisfy({ $0.tokenKind == specifiers.first?.tokenKind })
    {
      violations.append(contentsOf: specifiers.map(\.positionAfterSkippingLeadingTrivia))
    }
  }
}

extension LabeledExprListSyntax {
  fileprivate func flatteningEnumPatterns() -> [LabeledExprSyntax] {
    flatMap { elem in
      guard let pattern = elem.expression.as(FunctionCallExprSyntax.self),
        pattern.calledExpression.is(MemberAccessExprSyntax.self)
      else {
        return [elem]
      }

      return Array(pattern.arguments)
    }
  }
}

private enum ArgumentType {
  case binding(specifier: TokenSyntax)
  case reference
  case constant

  var isReference: Bool {
    switch self {
    case .reference: true
    default: false
    }
  }
}

extension ExprSyntax {
  fileprivate var categorized: ArgumentType {
    if let binding = `as`(PatternExprSyntax.self)?.pattern.as(ValueBindingPatternSyntax.self) {
      return .binding(specifier: binding.bindingSpecifier)
    }
    if `is`(DeclReferenceExprSyntax.self) {
      return .reference
    }
    return .constant
  }
}
