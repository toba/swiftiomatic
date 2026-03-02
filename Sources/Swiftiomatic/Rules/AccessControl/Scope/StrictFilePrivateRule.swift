import SwiftSyntax

struct StrictFilePrivateRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = StrictFilePrivateConfiguration()
}

extension StrictFilePrivateRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension StrictFilePrivateRule {}

private enum ProtocolRequirementType: Equatable {
  case method(String)
  case getter(String)
  case setter(String)
}

extension StrictFilePrivateRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private lazy var protocols = ProtocolCollector(configuration: configuration, file: file)
      .walk(tree: file.syntaxTree, handler: \.protocols)

    override func visitPost(_ node: DeclModifierSyntax) {
      guard node.name.tokenKind == .keyword(.fileprivate),
        let grandparent = node.parent?.parent
      else {
        return
      }
      guard grandparent.is(FunctionDeclSyntax.self) || grandparent.is(VariableDeclSyntax.self)
      else {
        violations.append(node.positionAfterSkippingLeadingTrivia)
        return
      }
      let protocolMethodNames = implementedTypesInDecl(of: node).flatMap {
        protocols[$0, default: []]
      }
      if let funcDecl = grandparent.as(FunctionDeclSyntax.self),
        protocolMethodNames.contains(.method(funcDecl.name.text))
      {
        return
      }
      if let varDecl = grandparent.as(VariableDeclSyntax.self) {
        let isSpecificForSetter = node.detail?.detail.tokenKind == .identifier("set")
        let firstImplementingProtocol = varDecl.bindings
          .flatMap { binding in
            let pattern = binding.pattern
            if let name = pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
              return [name]
            }
            if let tuple = pattern.as(TuplePatternSyntax.self) {
              return tuple.elements.compactMap {
                $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
              }
            }
            return []
          }
          .first {
            protocolMethodNames
              .contains(isSpecificForSetter ? .setter($0) : .getter($0))
          }
        if firstImplementingProtocol != nil {
          return
        }
      }
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }

    private func implementedTypesInDecl(of node: (some SyntaxProtocol)?) -> [String] {
      guard let node else {
        Console.fatalError("Given node is nil. That should not happen.")
      }
      if node.is(SourceFileSyntax.self) {
        return []
      }
      if let actorDecl = node.as(ActorDeclSyntax.self) {
        return actorDecl.inheritanceClause.inheritedTypeNames
      }
      if let classDecl = node.as(ClassDeclSyntax.self) {
        return classDecl.inheritanceClause.inheritedTypeNames
      }
      if let enumDecl = node.as(EnumDeclSyntax.self) {
        return enumDecl.inheritanceClause.inheritedTypeNames
      }
      if let extensionDecl = node.as(ExtensionDeclSyntax.self) {
        return extensionDecl.inheritanceClause.inheritedTypeNames
      }
      if let structDecl = node.as(StructDeclSyntax.self) {
        return structDecl.inheritanceClause.inheritedTypeNames
      }
      return implementedTypesInDecl(of: node.parent)
    }
  }
}

private final class ProtocolCollector<Configuration: RuleOptions>: ViolationCollectingVisitor<
  Configuration,
>
{
  private(set) var protocols = [String: [ProtocolRequirementType]]()
  private var currentProtocolName = ""

  override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
    .allExcept(ProtocolDeclSyntax.self)
  }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    currentProtocolName = node.name.text
    return .visitChildren
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    protocols[currentProtocolName, default: []].append(.method(node.name.text))
    return .skipChildren
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    for binding in node.bindings {
      guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
        let accessorBlock = binding.accessorBlock
      else {
        continue
      }
      if accessorBlock.specifiesGetAccessor {
        protocols[currentProtocolName, default: []].append(.getter(name))
      }
      if accessorBlock.specifiesSetAccessor {
        protocols[currentProtocolName, default: []].append(.setter(name))
      }
    }
    return .skipChildren
  }
}

extension InheritanceClauseSyntax? {
  fileprivate var inheritedTypeNames: [String] {
    self?.inheritedTypes.compactMap { $0.type.as(IdentifierTypeSyntax.self)?.name.text } ?? []
  }
}
