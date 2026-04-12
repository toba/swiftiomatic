import SwiftiomaticSyntax

/// this rule exists due to a compiler bug: https://github.com/apple/swift/issues/51036
struct NSNumberInitAsFunctionReferenceRule {
  static let id = "ns_number_init_as_function_reference"
  static let name = "NSNumber Init as Function Reference"
  static let summary =
    "Passing `NSNumber.init` or `NSDecimalNumber.init` as a function reference is dangerous as it can cause the wrong initializer to be used, causing crashes; use `.init(value:)` instead"
  static var nonTriggeringExamples: [Example] {
    [
      Example("[0, 0.2].map(NSNumber.init(value:))"),
      Example("let value = NSNumber.init(value: 0.0)"),
      Example("[0, 0.2].map { NSNumber(value: $0) }"),
      Example("[0, 0.2].map(NSDecimalNumber.init(value:))"),
      Example("[0, 0.2].map { NSDecimalNumber(value: $0) }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("[0, 0.2].map(↓NSNumber.init)"),
      Example("[0, 0.2].map(↓NSDecimalNumber.init)"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension NSNumberInitAsFunctionReferenceRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NSNumberInitAsFunctionReferenceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard node.declName.argumentNames.isEmptyOrNil,
        node.declName.baseName.text == "init",
        node.parent?.as(FunctionCallExprSyntax.self) == nil,
        let baseText = node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text,
        baseText == "NSNumber" || baseText == "NSDecimalNumber"
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension DeclNameArgumentsSyntax? {
  fileprivate var isEmptyOrNil: Bool {
    self?.arguments.isEmpty ?? true
  }
}
