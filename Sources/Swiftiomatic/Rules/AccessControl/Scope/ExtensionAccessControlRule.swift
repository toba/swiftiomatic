import SwiftSyntax

struct ExtensionAccessControlRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ExtensionAccessControlConfiguration()
}

extension ExtensionAccessControlRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ExtensionAccessControlRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ExtensionDeclSyntax) {
      // Skip if extension already has an access modifier
      let hasExtensionACL = node.modifiers.contains(where: { modifier in
        let kind = modifier.name.tokenKind
        return kind == .keyword(.public) || kind == .keyword(.private)
          || kind == .keyword(.fileprivate) || kind == .keyword(.internal)
          || kind == .keyword(.package) || kind == .keyword(.open)
      })
      guard !hasExtensionACL else { return }

      // Collect access levels of all members
      let memberACLs = node.memberBlock.members.compactMap { member -> TokenKind? in
        let modifiers: DeclModifierListSyntax
        if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
          modifiers = funcDecl.modifiers
        } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
          modifiers = varDecl.modifiers
        } else if let classDecl = member.decl.as(ClassDeclSyntax.self) {
          modifiers = classDecl.modifiers
        } else if let structDecl = member.decl.as(StructDeclSyntax.self) {
          modifiers = structDecl.modifiers
        } else if let enumDecl = member.decl.as(EnumDeclSyntax.self) {
          modifiers = enumDecl.modifiers
        } else if let typeAlias = member.decl.as(TypeAliasDeclSyntax.self) {
          modifiers = typeAlias.modifiers
        } else if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
          modifiers = initDecl.modifiers
        } else {
          return nil
        }

        for modifier in modifiers {
          let kind = modifier.name.tokenKind
          if kind == .keyword(.public) || kind == .keyword(.private)
            || kind == .keyword(.fileprivate) || kind == .keyword(.internal)
            || kind == .keyword(.package) || kind == .keyword(.open)
          {
            return kind
          }
        }
        return nil
      }

      // If all members have the same explicit ACL, it can be hoisted
      guard memberACLs.count >= 2 else { return }

      let firstACL = memberACLs[0]
      guard memberACLs.allSatisfy({ $0 == firstACL }) else { return }

      // Don't suggest hoisting `private` (it changes semantics)
      guard firstACL != .keyword(.private) else { return }

      // Report on the first member's ACL modifier
      if let firstMember = node.memberBlock.members.first {
        violations.append(firstMember.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
