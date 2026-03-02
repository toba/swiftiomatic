import SwiftSyntax

struct ImplicitReturnRule {
    static let id = "implicit_return"
    static let name = "Implicit Return"
    static let summary = "Prefer implicit returns in closures, functions and getters"
    static let isCorrectable = true
    static let isOptIn = true
  var options = ImplicitReturnOptions()

}

extension ImplicitReturnRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ImplicitReturnRule {}

extension ImplicitReturnRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: AccessorDeclSyntax) {
      if configuration.isKindIncluded(.getter),
        node.accessorSpecifier.tokenKind == .keyword(.get),
        let body = node.body
      {
        collectViolation(in: body.statements)
      }
    }

    override func visitPost(_ node: ClosureExprSyntax) {
      if configuration.isKindIncluded(.closure) {
        collectViolation(in: node.statements)
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if configuration.isKindIncluded(.function),
        let body = node.body
      {
        collectViolation(in: body.statements)
      }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      if configuration.isKindIncluded(.initializer),
        let body = node.body
      {
        collectViolation(in: body.statements)
      }
    }

    override func visitPost(_ node: PatternBindingSyntax) {
      if configuration.isKindIncluded(.getter),
        case .getter(let itemList) = node.accessorBlock?.accessors
      {
        collectViolation(in: itemList)
      }
    }

    override func visitPost(_ node: SubscriptDeclSyntax) {
      if configuration.isKindIncluded(.subscript),
        case .getter(let itemList) = node.accessorBlock?.accessors
      {
        collectViolation(in: itemList)
      }
    }

    private func collectViolation(in itemList: CodeBlockItemListSyntax) {
      guard let returnStmt = itemList.onlyElement?.item.as(ReturnStmtSyntax.self) else {
        return
      }
      let returnKeyword = returnStmt.returnKeyword
      violations.append(
        at: returnKeyword.positionAfterSkippingLeadingTrivia,
        correction: .init(
          start: returnKeyword.positionAfterSkippingLeadingTrivia,
          end: returnKeyword.endPositionBeforeTrailingTrivia
            .advanced(by: returnStmt.expression == nil ? 0 : 1),
          replacement: "",
        ),
      )
    }
  }
}
