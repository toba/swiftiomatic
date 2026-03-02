import SwiftSyntax

struct OrganizeDeclarationsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = OrganizeDeclarationsConfiguration()
}

extension OrganizeDeclarationsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OrganizeDeclarationsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: StructDeclSyntax) {
      checkOrganization(
        members: node.memberBlock.members, at: node.name.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      checkOrganization(
        members: node.memberBlock.members, at: node.name.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      checkOrganization(
        members: node.memberBlock.members, at: node.name.positionAfterSkippingLeadingTrivia)
    }

    private func checkOrganization(
      members: MemberBlockItemListSyntax, at position: AbsolutePosition
    ) {
      guard members.count >= 3 else { return }

      // Categorize each member
      let categories = members.compactMap { member -> MemberCategory? in
        categorize(member.decl)
      }

      // Check if categories are in order
      var lastCategory = MemberCategory.typeAlias
      var outOfOrder = false
      for category in categories {
        if category.order < lastCategory.order {
          outOfOrder = true
          break
        }
        lastCategory = category
      }

      if outOfOrder {
        violations.append(position)
      }
    }

    private func categorize(_ decl: DeclSyntax) -> MemberCategory? {
      if decl.is(TypeAliasDeclSyntax.self) { return .typeAlias }
      if decl.is(EnumDeclSyntax.self) || decl.is(StructDeclSyntax.self)
        || decl.is(ClassDeclSyntax.self)
      {
        return .nestedType
      }
      if let varDecl = decl.as(VariableDeclSyntax.self) {
        let isStatic = varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
        return isStatic ? .staticProperty : .instanceProperty
      }
      if decl.is(InitializerDeclSyntax.self) || decl.is(DeinitializerDeclSyntax.self) {
        return .lifecycle
      }
      if let funcDecl = decl.as(FunctionDeclSyntax.self) {
        let isStatic = funcDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }
        )
        return isStatic ? .staticMethod : .instanceMethod
      }
      return nil
    }
  }

  fileprivate enum MemberCategory {
    case typeAlias
    case nestedType
    case staticProperty
    case instanceProperty
    case lifecycle
    case staticMethod
    case instanceMethod

    var order: Int {
      switch self {
      case .typeAlias: 0
      case .nestedType: 1
      case .staticProperty: 2
      case .instanceProperty: 3
      case .lifecycle: 4
      case .staticMethod: 5
      case .instanceMethod: 6
      }
    }
  }
}
