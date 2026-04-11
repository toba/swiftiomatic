import SwiftSyntax

struct DiscouragedDirectInitRule {
  static let id = "discouraged_direct_init"
  static let name = "Discouraged Direct Initialization"
  static let summary = "Avoid directly initializing types like `Bundle()` or `UIDevice()` that have preferred alternatives"
  static var nonTriggeringExamples: [Example] {
    [
      Example("let foo = UIDevice.current"),
      Example("let foo = Bundle.main"),
      Example("let foo = Bundle(path: \"bar\")"),
      Example("let foo = Bundle(identifier: \"bar\")"),
      Example("let foo = Bundle.init(path: \"bar\")"),
      Example("let foo = Bundle.init(identifier: \"bar\")"),
      Example("let foo = NSError(domain: \"bar\", code: 0)"),
      Example("let foo = NSError.init(domain: \"bar\", code: 0)"),
      Example("func testNSError()"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓UIDevice()"),
      Example("↓Bundle()"),
      Example("let foo = ↓UIDevice()"),
      Example("let foo = ↓Bundle()"),
      Example("let foo = ↓NSError()"),
      Example("let foo = bar(bundle: ↓Bundle(), device: ↓UIDevice(), error: ↓NSError())"),
      Example("↓UIDevice.init()"),
      Example("↓Bundle.init()"),
      Example("↓NSError.init()"),
      Example("let foo = ↓UIDevice.init()"),
      Example("let foo = ↓Bundle.init()"),
      Example(
        "let foo = bar(bundle: ↓Bundle.init(), device: ↓UIDevice.init(), error: ↓NSError.init())",
      ),
    ]
  }

  var options = DiscouragedDirectInitOptions()
}

extension DiscouragedDirectInitRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedDirectInitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard node.arguments.isEmpty, node.trailingClosure == nil,
        configuration.discouragedInits.contains(node.calledExpression.trimmedDescription)
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
