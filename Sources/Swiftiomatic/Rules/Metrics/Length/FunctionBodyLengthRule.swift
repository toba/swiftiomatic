import SwiftSyntax

struct FunctionBodyLengthRule {
  var options = SeverityLevelsConfiguration<Self>(warning: 50, error: 100)

  static let configuration = FunctionBodyLengthConfiguration()
}

extension FunctionBodyLengthRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FunctionBodyLengthRule {
  fileprivate final class Visitor: BodyLengthVisitor<OptionsType> {
    override func visitPost(_ node: DeinitializerDeclSyntax) {
      if let body = node.body {
        registerViolations(
          leftBrace: body.leftBrace,
          rightBrace: body.rightBrace,
          violationNode: node.deinitKeyword,
          objectName: "Deinitializer",
        )
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if let body = node.body {
        registerViolations(
          leftBrace: body.leftBrace,
          rightBrace: body.rightBrace,
          violationNode: node.funcKeyword,
          objectName: "Function",
        )
      }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      if let body = node.body {
        registerViolations(
          leftBrace: body.leftBrace,
          rightBrace: body.rightBrace,
          violationNode: node.initKeyword,
          objectName: "Initializer",
        )
      }
    }

    override func visitPost(_ node: SubscriptDeclSyntax) {
      guard let body = node.accessorBlock else {
        return
      }
      if case .getter = body.accessors {
        registerViolations(
          leftBrace: body.leftBrace,
          rightBrace: body.rightBrace,
          violationNode: node.subscriptKeyword,
          objectName: "Subscript",
        )
      }
      if case .accessors(let accessors) = body.accessors {
        for accessor in accessors {
          guard let body = accessor.body else {
            continue
          }
          registerViolations(
            leftBrace: body.leftBrace,
            rightBrace: body.rightBrace,
            violationNode: accessor.accessorSpecifier,
            objectName: "Accessor",
          )
        }
      }
    }
  }
}
