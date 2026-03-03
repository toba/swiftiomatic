import SwiftSyntax

struct UntypedErrorInCatchRule {
    static let id = "untyped_error_in_catch"
    static let name = "Untyped Error in Catch"
    static let summary = "Catch statements should not declare error variables without type casting"
    static let isCorrectable = true
    static let isOptIn = true
    static let deprecatedAliases: Set<String> = ["redundant_let_error"]
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                do {
                  try foo()
                } catch {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } catch Error.invalidOperation {
                } catch {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } catch let error as MyError {
                } catch {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } catch var error as MyError {
                } catch {}
                """,
              ),
              Example(
                """
                do {
                    try something()
                } catch let e where e.code == .fileError {
                    // can be ignored
                } catch {
                    print(error)
                }
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                do {
                  try foo()
                } ↓catch var error {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch let error {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch let someError {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch var someError {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch let e {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch(let error) {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch (let error) {}
                """,
              ),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("do {\n    try foo() \n} ↓catch let error {}"): Example(
                "do {\n    try foo() \n} catch {}",
              ),
              Example("do {\n    try foo() \n} ↓catch(let error) {}"): Example(
                "do {\n    try foo() \n} catch {}",
              ),
              Example("do {\n    try foo() \n} ↓catch (let error) {}"): Example(
                "do {\n    try foo() \n} catch {}",
              ),
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension UntypedErrorInCatchRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension UntypedErrorInCatchRule {}

extension CatchItemSyntax {
  fileprivate var isIdentifierPattern: Bool {
    guard whereClause == nil else {
      return false
    }

    if let pattern = pattern?.as(ValueBindingPatternSyntax.self) {
      return pattern.pattern.is(IdentifierPatternSyntax.self)
    }

    if let pattern = pattern?.as(ExpressionPatternSyntax.self),
      let tupleExpr = pattern.expression.as(TupleExprSyntax.self),
      let tupleElement = tupleExpr.elements.onlyElement,
      let unresolvedPattern = tupleElement.expression.as(PatternExprSyntax.self),
      let valueBindingPattern = unresolvedPattern.pattern.as(ValueBindingPatternSyntax.self)
    {
      return valueBindingPattern.pattern.is(IdentifierPatternSyntax.self)
    }

    return false
  }
}

extension UntypedErrorInCatchRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: CatchClauseSyntax) {
      guard let item = node.catchItems.onlyElement, item.isIdentifierPattern else {
        return
      }
      violations.append(node.catchKeyword.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
      guard let item = node.catchItems.onlyElement, item.isIdentifierPattern else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return super.visit(
        node
          .with(\.catchKeyword, node.catchKeyword.with(\.trailingTrivia, .spaces(1)))
          .with(\.catchItems, CatchItemListSyntax([])),
      )
    }
  }
}
