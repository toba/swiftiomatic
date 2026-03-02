import SwiftSyntax

struct ReturnArrowWhitespaceRule {
    static let id = "return_arrow_whitespace"
    static let name = "Returning Whitespace"
    static let summary = "Return arrow and return type should be separated by a single space or on a separate line"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("func abc() -> Int {}"),
              Example("func abc() -> [Int] {}"),
              Example("func abc() -> (Int, Int) {}"),
              Example("var abc = {(param: Int) -> Void in }"),
              Example("func abc() ->\n    Int {}"),
              Example("func abc()\n    -> Int {}"),
              Example(
                """
                func reallyLongFunctionMethods<T>(withParam1: Int, param2: String, param3: Bool) where T: AGenericConstraint
                    -> Int {
                    return 1
                }
                """,
              ),
              Example("typealias SuccessBlock = ((Data) -> Void)"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("func abc()↓->Int {}"),
              Example("func abc()↓->[Int] {}"),
              Example("func abc()↓->(Int, Int) {}"),
              Example("func abc()↓-> Int {}"),
              Example("func abc()↓->   Int {}"),
              Example("func abc()↓ ->Int {}"),
              Example("func abc()↓  ->  Int {}"),
              Example("var abc = {(param: Int)↓ ->Bool in }"),
              Example("var abc = {(param: Int)↓->Bool in }"),
              Example("typealias SuccessBlock = ((Data)↓->Void)"),
              Example("func abc()\n  ↓->  Int {}"),
              Example("func abc()\n ↓->  Int {}"),
              Example("func abc()↓  ->\n  Int {}"),
              Example("func abc()↓  ->\nInt {}"),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("func abc()↓->Int {}"): Example("func abc() -> Int {}"),
              Example("func abc()↓-> Int {}"): Example("func abc() -> Int {}"),
              Example("func abc()↓ ->Int {}"): Example("func abc() -> Int {}"),
              Example("func abc()↓  ->  Int {}"): Example("func abc() -> Int {}"),
              Example("func abc()\n  ↓->  Int {}"): Example("func abc()\n  -> Int {}"),
              Example("func abc()\n ↓->  Int {}"): Example("func abc()\n -> Int {}"),
              Example("func abc()↓  ->\n  Int {}"): Example("func abc() ->\n  Int {}"),
              Example("func abc()↓  ->\nInt {}"): Example("func abc() ->\nInt {}"),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension ReturnArrowWhitespaceRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ReturnArrowWhitespaceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionTypeSyntax) {
      if let violation = node.returnClause.arrow.arrowViolation {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: FunctionSignatureSyntax) {
      if let output = node.returnClause, let violation = output.arrow.arrowViolation {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: ClosureSignatureSyntax) {
      if let output = node.returnClause, let violation = output.arrow.arrowViolation {
        violations.append(violation)
      }
    }
  }
}

extension TokenSyntax {
  fileprivate var arrowViolation: SyntaxViolation? {
    guard let previousToken = previousToken(viewMode: .sourceAccurate),
      let nextToken = nextToken(viewMode: .sourceAccurate)
    else {
      return nil
    }

    var start: AbsolutePosition?
    var end: AbsolutePosition?
    var correction = " -> "

    if previousToken.trailingTrivia != .space, !leadingTrivia.containsNewlines() {
      start = previousToken.endPositionBeforeTrailingTrivia
      end = endPosition

      if nextToken.leadingTrivia.containsNewlines() {
        correction = " ->"
      }
    }

    if trailingTrivia != .space, !nextToken.leadingTrivia.containsNewlines() {
      if leadingTrivia.containsNewlines() {
        start = positionAfterSkippingLeadingTrivia
        correction = "-> "
      } else {
        start = previousToken.endPositionBeforeTrailingTrivia
      }
      end = endPosition
    }

    guard let start, let end else {
      return nil
    }

    return .init(
      position: start, correction: .init(start: start, end: end, replacement: correction),
    )
  }
}
