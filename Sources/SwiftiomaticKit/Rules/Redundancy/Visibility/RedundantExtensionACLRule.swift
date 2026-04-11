import SwiftSyntax

struct RedundantExtensionACLRule {
  static let id = "redundant_extension_acl"
  static let name = "Redundant Extension ACL"
  static let summary =
    "Access control modifiers on extension members are redundant when they match the extension's ACL"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        public extension URL {
          func queryParameter(_ name: String) -> String { "" }
        }
        """,
      ),
      Example(
        """
        public extension URL {
          internal func internalMethod() {}
        }
        """,
      ),
      Example(
        """
        extension URL {
          public func publicMethod() {}
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        public extension URL {
          ↓public func queryParameter(_ name: String) -> String { "" }
        }
        """,
      ),
      Example(
        """
        private extension URL {
          ↓fileprivate func foo() {}
        }
        """,
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        public extension URL {
          ↓public func queryParameter(_ name: String) -> String { "" }
        }
        """,
      ): Example(
        """
        public extension URL {
          func queryParameter(_ name: String) -> String { "" }
        }
        """,
      )
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension RedundantExtensionACLRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantExtensionACLRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ExtensionDeclSyntax) {
      guard let extensionACL = node.effectiveACLKeyword else { return }
      let memberACL = extensionACL == .private ? Keyword.fileprivate : extensionACL
      for member in node.memberBlock.members {
        guard let modifiers = member.decl.asProtocol(WithModifiersSyntax.self)?.modifiers
        else {
          continue
        }
        for modifier in modifiers {
          if modifier.name.tokenKind == .keyword(memberACL), modifier.detail == nil {
            violations.append(modifier.positionAfterSkippingLeadingTrivia)
          }
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
      guard let extensionACL = node.effectiveACLKeyword else {
        return super.visit(node)
      }
      let memberACL = extensionACL == .private ? Keyword.fileprivate : extensionACL

      var newNode = node
      let newMembers = MemberBlockItemListSyntax(
        node.memberBlock.members.map { member in
          guard let withModifiers = member.decl.asProtocol(WithModifiersSyntax.self)
          else {
            return member
          }
          let modifiers = withModifiers.modifiers
          let redundant = modifiers.filter {
            $0.name.tokenKind == .keyword(memberACL) && $0.detail == nil
          }
          guard redundant.isNotEmpty else { return member }

          numberOfCorrections += redundant.count
          let newModifiers = modifiers.filter {
            $0.name.tokenKind != .keyword(memberACL) || $0.detail != nil
          }
          let newDecl = member.decl.removingACLModifier(
            memberACL,
            replacingWith: newModifiers,
          )
          return member.with(\.decl, newDecl)
        },
      )
      newNode.memberBlock.members = newMembers
      return super.visit(DeclSyntax(newNode))
    }
  }
}

extension DeclSyntax {
  fileprivate func removingACLModifier(
    _: Keyword, replacingWith newModifiers: DeclModifierListSyntax,
  ) -> DeclSyntax {
    if var funcDecl = self.as(FunctionDeclSyntax.self) {
      funcDecl.modifiers = newModifiers
      return DeclSyntax(funcDecl)
    }
    if var varDecl = self.as(VariableDeclSyntax.self) {
      varDecl.modifiers = newModifiers
      return DeclSyntax(varDecl)
    }
    if var structDecl = self.as(StructDeclSyntax.self) {
      structDecl.modifiers = newModifiers
      return DeclSyntax(structDecl)
    }
    if var classDecl = self.as(ClassDeclSyntax.self) {
      classDecl.modifiers = newModifiers
      return DeclSyntax(classDecl)
    }
    if var enumDecl = self.as(EnumDeclSyntax.self) {
      enumDecl.modifiers = newModifiers
      return DeclSyntax(enumDecl)
    }
    if var typealiasDecl = self.as(TypeAliasDeclSyntax.self) {
      typealiasDecl.modifiers = newModifiers
      return DeclSyntax(typealiasDecl)
    }
    if var initDecl = self.as(InitializerDeclSyntax.self) {
      initDecl.modifiers = newModifiers
      return DeclSyntax(initDecl)
    }
    if var subscriptDecl = self.as(SubscriptDeclSyntax.self) {
      subscriptDecl.modifiers = newModifiers
      return DeclSyntax(subscriptDecl)
    }
    return self
  }
}

extension ExtensionDeclSyntax {
  fileprivate var effectiveACLKeyword: Keyword? {
    for modifier in modifiers {
      switch modifier.name.tokenKind {
      case .keyword(.public): return .public
      case .keyword(.package): return .package
      case .keyword(.internal): return .internal
      case .keyword(.private): return .private
      case .keyword(.fileprivate): return .fileprivate
      default: continue
      }
    }
    return nil
  }
}
