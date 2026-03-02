import SwiftSyntax

struct NoGroupingExtensionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NoGroupingExtensionConfiguration()

  func validate(file: SwiftSource) -> [RuleViolation] {
    Visitor(configuration: options, file: file)
      .walk(tree: file.syntaxTree) { visitor in
        visitor.extensionDeclarations.compactMap { decl in
          guard visitor.typeDeclarations.contains(decl.name) else {
            return nil
          }

          return SyntaxViolation(position: decl.position)
        }
      }
      .sorted()
      .map { makeViolation(file: file, violation: $0) }
  }
}

extension NoGroupingExtensionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoGroupingExtensionRule {}

extension NoGroupingExtensionRule {
  fileprivate struct ExtensionDeclaration: Hashable {
    let name: String
    let position: AbsolutePosition
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private(set) var typeDeclarations = Set<String>()
    private var typeScope: [String] = []
    private(set) var extensionDeclarations = Set<ExtensionDeclaration>()

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [
        ProtocolDeclSyntax.self,
        FunctionDeclSyntax.self,
        VariableDeclSyntax.self,
        InitializerDeclSyntax.self,
        SubscriptDeclSyntax.self,
      ]
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
      pushType(named: node.name.text)
      return .visitChildren
    }

    override func visitPost(_: ActorDeclSyntax) {
      typeScope.removeLast()
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      pushType(named: node.name.text)
      return .visitChildren
    }

    override func visitPost(_: ClassDeclSyntax) {
      typeScope.removeLast()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      pushType(named: node.name.text)
      return .visitChildren
    }

    override func visitPost(_: EnumDeclSyntax) {
      typeScope.removeLast()
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
      pushType(named: node.name.text)
      return .visitChildren
    }

    override func visitPost(_: StructDeclSyntax) {
      typeScope.removeLast()
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
      typeScope.append(node.extendedType.trimmedDescription)

      guard node.genericWhereClause == nil else {
        return .skipChildren
      }

      let decl = ExtensionDeclaration(
        name: node.extendedType.trimmedDescription,
        position: node.extensionKeyword.positionAfterSkippingLeadingTrivia,
      )
      extensionDeclarations.insert(decl)
      return .visitChildren
    }

    override func visitPost(_: ExtensionDeclSyntax) {
      typeScope.removeLast()
    }

    private func pushType(named name: String) {
      typeScope.append(name)
      typeDeclarations.insert(typeScope.joined(separator: "."))
    }
  }
}
