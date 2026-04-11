import SwiftSyntax

struct IdenticalOperandsRule {
  static let operators = ["==", "!=", "===", "!==", ">", ">=", "<", "<="]
  static let id = "identical_operands"
  static let name = "Identical Operands"
  static let summary = "Comparing two identical operands is likely a mistake"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    operators.flatMap { operation in
      [
        Example("1 \(operation) 2"),
        Example("foo \(operation) bar"),
        Example("prefixedFoo \(operation) foo"),
        Example("foo.aProperty \(operation) foo.anotherProperty"),
        Example("self.aProperty \(operation) self.anotherProperty"),
        Example("\"1 \(operation) 1\""),
        Example("self.aProperty \(operation) aProperty"),
        Example("lhs.aProperty \(operation) rhs.aProperty"),
        Example("lhs.identifier \(operation) rhs.identifier"),
        Example("i \(operation) index"),
        Example("$0 \(operation) 0"),
        Example("keyValues?.count ?? 0 \(operation) 0"),
        Example("string \(operation) string.lowercased()"),
        Example(
          """
          let num: Int? = 0
          _ = num != nil && num \(operation) num?.byteSwapped
          """,
        ),
        Example("num \(operation) num!.byteSwapped"),
        Example("1    + 1 \(operation)   1     +    2"),
        Example("f(  i :   2) \(operation)   f (i: 3 )"),
      ]
    } + [
      Example(
        "func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CommandantError<()>>>",
      ),
      Example("let array = Array<Array<Int>>()"),
      Example("guard Set(identifiers).count != identifiers.count else { return }"),
      Example(#"expect("foo") == "foo""#),
      Example("type(of: model).cachePrefix == cachePrefix"),
      Example("histogram[156].0 == 0x003B8D96 && histogram[156].1 == 1"),
      Example(
        #"[Wrapper(type: .three), Wrapper(type: .one)].sorted { "\($0.type)" > "\($1.type)"}"#,
      ),
      Example(#"array.sorted { "\($0)" < "\($1)" }"#),
    ]
  }

  static var triggeringExamples: [Example] {
    operators.flatMap { operation in
      [
        Example("↓1 \(operation) 1"),
        Example("↓foo \(operation) foo"),
        Example("↓foo.aProperty \(operation) foo.aProperty"),
        Example("↓self.aProperty \(operation) self.aProperty"),
        Example("↓$0 \(operation) $0"),
        Example("↓a?.b \(operation) a?.b"),
        Example("if (↓elem \(operation) elem) {}"),
        Example("XCTAssertTrue(↓s3 \(operation) s3)"),
        Example(
          "if let tab = tabManager.selectedTab, ↓tab.webView \(operation) tab.webView",
        ),
        Example("↓1    + 1 \(operation)   1     +    1"),
        Example(" ↓f(  i :   2) \(operation)   f (i: \n 2 )"),
      ]
    } + [
      Example(
        """
            return ↓lhs.foo == lhs.foo &&
                   lhs.bar == rhs.bar
        """,
      ),
      Example(
        """
            return lhs.foo == rhs.foo &&
                   ↓lhs.bar == lhs.bar
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension IdenticalOperandsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension IdenticalOperandsRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension IdenticalOperandsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
        IdenticalOperandsRule.operators.contains(operatorNode.operator.text)
      else {
        return
      }

      if node.leftOperand.normalizedDescription == node.rightOperand.normalizedDescription {
        violations.append(node.leftOperand.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension ExprSyntax {
  fileprivate var normalizedDescription: String {
    debugDescription(includeTrivia: false)
  }
}
