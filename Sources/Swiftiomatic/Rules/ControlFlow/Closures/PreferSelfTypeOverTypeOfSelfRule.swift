import SwiftSyntax
import SwiftSyntaxBuilder

struct PreferSelfTypeOverTypeOfSelfRule {
    static let id = "prefer_self_type_over_type_of_self"
    static let name = "Prefer Self Type Over Type of Self"
    static let summary = "Prefer `Self` over `type(of: self)` when accessing properties or calling methods"
    static let isCorrectable = true
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                    func bar() {
                        Self.baz()
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(Self.baz)
                    }
                }
                """,
              ),
              Example(
                """
                class A {
                    func foo(param: B) {
                        type(of: param).bar()
                    }
                }
                """,
              ),
              Example(
                """
                class A {
                    func foo() {
                        print(type(of: self))
                    }
                }
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                    func bar() {
                        ↓type(of: self).baz()
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(↓type(of: self).baz)
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(↓Swift.type(of: self).baz)
                    }
                }
                """,
              ),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example(
                """
                class Foo {
                    func bar() {
                        ↓type(of: self).baz()
                    }
                }
                """,
              ): Example(
                """
                class Foo {
                    func bar() {
                        Self.baz()
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(↓type(of: self).baz)
                    }
                }
                """,
              ): Example(
                """
                class Foo {
                    func bar() {
                        print(Self.baz)
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    func bar() {
                        print(↓Swift.type(of: self).baz)
                    }
                }
                """,
              ): Example(
                """
                class Foo {
                    func bar() {
                        print(Self.baz)
                    }
                }
                """,
              ),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension PreferSelfTypeOverTypeOfSelfRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension PreferSelfTypeOverTypeOfSelfRule {}

extension PreferSelfTypeOverTypeOfSelfRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      if let function = node.base?.as(FunctionCallExprSyntax.self), function.hasViolation {
        violations.append(function.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
      guard let function = node.base?.as(FunctionCallExprSyntax.self),
        function.hasViolation
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let base = DeclReferenceExprSyntax(baseName: "Self")
      let baseWithTrivia =
        base
        .with(\.leadingTrivia, function.leadingTrivia)
        .with(\.trailingTrivia, function.trailingTrivia)
      return super.visit(node.with(\.base, ExprSyntax(baseWithTrivia)))
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var hasViolation: Bool {
    isTypeOfSelfCall && arguments.map(\.label?.text) == ["of"]
      && arguments.first?.expression.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind
        == .keyword(.self)
  }

  fileprivate var isTypeOfSelfCall: Bool {
    if let identifierExpr = calledExpression.as(DeclReferenceExprSyntax.self) {
      return identifierExpr.baseName.text == "type"
    }
    if let memberAccessExpr = calledExpression.as(MemberAccessExprSyntax.self) {
      return memberAccessExpr.declName.baseName.text == "type"
        && memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Swift"
    }
    return false
  }
}
