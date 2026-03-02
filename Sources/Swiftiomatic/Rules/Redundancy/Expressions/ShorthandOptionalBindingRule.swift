import SwiftSyntax

struct ShorthandOptionalBindingRule {
    static let id = "shorthand_optional_binding"
    static let name = "Shorthand Optional Binding"
    static let summary = "Use shorthand syntax for optional binding"
    static let isCorrectable = true
    static let isOptIn = true
    static let deprecatedAliases: Set<String> = ["if_let_shadowing"]
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                if let i {}
                if let i = a {}
                guard let i = f() else {}
                if var i = i() {}
                if let i = i as? Foo {}
                guard let `self` = self else {}
                while var i { i = nil }
                """,
              ),
              Example(
                """
                if let i,
                   var i = a,
                   j > 0 {}
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                if ↓let i = i {}
                if ↓let self = self {}
                if ↓var `self` = `self` {}
                if i > 0, ↓let j = j {}
                if ↓let i = i, ↓var j = j {}
                """,
              ),
              Example(
                """
                if ↓let i = i,
                   ↓var j = j,
                   j > 0 {}
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                guard ↓let i = i else {}
                guard ↓let self = self else {}
                guard ↓var `self` = `self` else {}
                guard i > 0, ↓let j = j else {}
                guard ↓let i = i, ↓var j = j else {}
                """,
              ),
              Example(
                """
                while ↓var i = i { i = nil }
                """,
              ),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example(
                """
                if ↓let i = i {}
                """,
              ): Example(
                """
                if let i {}
                """,
              ),
              Example(
                """
                if ↓let self = self {}
                """,
              ): Example(
                """
                if let self {}
                """,
              ),
              Example(
                """
                if ↓var `self` = `self` {}
                """,
              ): Example(
                """
                if var `self` {}
                """,
              ),
              Example(
                """
                guard ↓let i = i, ↓var j = j  , ↓let k  =k else {}
                """,
              ): Example(
                """
                guard let i, var j  , let k else {}
                """,
              ),
              Example(
                """
                while j > 0, ↓var i = i   { i = nil }
                """,
              ): Example(
                """
                while j > 0, var i   { i = nil }
                """,
              ),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension ShorthandOptionalBindingRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ShorthandOptionalBindingRule {}

extension ShorthandOptionalBindingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      if node.isShadowingOptionalBinding {
        violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: OptionalBindingConditionSyntax)
      -> OptionalBindingConditionSyntax
    {
      guard node.isShadowingOptionalBinding else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode =
        node
        .with(\.initializer, nil)
        .with(\.pattern, node.pattern.with(\.trailingTrivia, node.trailingTrivia))
      return super.visit(newNode)
    }
  }
}

extension OptionalBindingConditionSyntax {
  fileprivate var isShadowingOptionalBinding: Bool {
    if let id = pattern.as(IdentifierPatternSyntax.self),
      let value = initializer?.value.as(DeclReferenceExprSyntax.self),
      id.identifier.text == value.baseName.text
    {
      return true
    }
    return false
  }
}
