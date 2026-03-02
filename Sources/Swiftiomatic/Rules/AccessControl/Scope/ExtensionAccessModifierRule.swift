import SwiftSyntax

struct ExtensionAccessModifierRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ExtensionAccessModifierConfiguration()
}

extension ExtensionAccessModifierRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ExtensionAccessModifierRule {}

extension ExtensionAccessModifierRule {
  private enum ACL: Hashable {
    case implicit
    case explicit(TokenKind)

    static func from(tokenKind: TokenKind?) -> Self {
      switch tokenKind {
      case nil:
        return .implicit
      case let value?:
        return .explicit(value)
      }
    }

    static func isAllowed(_ acl: Self) -> Bool {
      [
        .explicit(.keyword(.internal)),
        .explicit(.keyword(.private)),
        .explicit(.keyword(.open)),
        .implicit,
      ].contains(acl)
    }
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
      guard node.inheritanceClause == nil else {
        return
      }

      var areAllACLsEqual = true
      var aclTokens = [(position: AbsolutePosition, acl: ACL)]()

      for decl in node.memberBlock.expandingIfConfigs() {
        let modifiers = decl.asProtocol((any WithModifiersSyntax).self)?.modifiers
        let aclToken = modifiers?.accessLevelModifier()?.name
        let acl = ACL.from(tokenKind: aclToken?.tokenKind)
        if areAllACLsEqual, acl != aclTokens.last?.acl, aclTokens.isNotEmpty {
          areAllACLsEqual = false
        }
        aclTokens.append((decl.positionAfterSkippingLeadingTrivia, acl))
      }

      guard areAllACLsEqual, let lastACL = aclTokens.last else {
        return
      }

      let isAllowedACL = ACL.isAllowed(lastACL.acl)
      let extensionACL =
        ACL
        .from(tokenKind: node.modifiers.accessLevelModifier?.name.tokenKind)

      if extensionACL != .implicit {
        if !isAllowedACL || lastACL.acl != extensionACL, lastACL.acl != .implicit {
          violations.append(contentsOf: aclTokens.map(\.position))
        }
      } else if !isAllowedACL {
        violations.append(node.extensionKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension MemberBlockSyntax {
  fileprivate func expandingIfConfigs() -> [DeclSyntax] {
    members.flatMap { member in
      if let ifConfig = member.decl.as(IfConfigDeclSyntax.self) {
        return ifConfig.clauses.flatMap { clause in
          switch clause.elements {
          case .decls(let decls):
            return decls.map(\.decl)
          default:
            return []
          }
        }
      }
      return [member.decl]
    }
  }
}
