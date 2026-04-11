import SwiftSyntax

struct EmptyXCTestMethodRule {
  static let id = "empty_xctest_method"
  static let name = "Empty XCTest Method"
  static let summary = "Empty XCTest method should be avoided"
  static let isOptIn = true
  var options = EmptyXCTestMethodOptions()
}

extension EmptyXCTestMethodRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension EmptyXCTestMethodRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      node.isXCTestCase(configuration.testParentClasses) ? .visitChildren : .skipChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if node.modifiers.contains(keyword: .override) || node.isTestMethod, node.hasEmptyBody {
        violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension FunctionDeclSyntax {
  fileprivate var hasEmptyBody: Bool {
    if let body {
      return body.statements.isEmpty
    }
    return false
  }

  fileprivate var isTestMethod: Bool {
    name.text.hasPrefix("test") && signature.parameterClause.parameters.isEmpty
  }
}
