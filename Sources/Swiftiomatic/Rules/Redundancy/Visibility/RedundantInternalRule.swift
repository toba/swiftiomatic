import SwiftSyntax

struct RedundantInternalRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantInternalConfiguration()
}

extension RedundantInternalRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantInternalRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclModifierSyntax) {
      guard node.isRedundantInternal else { return }
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: DeclModifierListSyntax) -> DeclModifierListSyntax {
      var modified = false
      let newModifiers = node.filter { modifier in
        if modifier.isRedundantInternal {
          modified = true
          numberOfCorrections += 1
          return false
        }
        return true
      }
      guard modified else { return super.visit(node) }

      // Preserve leading trivia from the removed modifier on the next token
      var result = newModifiers
      if let firstRemoved = node.first(where: \.isRedundantInternal),
        !result.isEmpty
      {
        let leadingTrivia = firstRemoved.leadingTrivia
        result = DeclModifierListSyntax(
          result.enumerated().map { index, element in
            index == 0
              ? element.with(\.leadingTrivia, leadingTrivia + element.leadingTrivia) : element
          },
        )
      }
      return super.visit(result)
    }
  }
}

extension DeclModifierSyntax {
  fileprivate var isRedundantInternal: Bool {
    guard name.tokenKind == .keyword(.internal), detail == nil else {
      return false
    }
    // Don't remove from import declarations
    if parent?.parent?.is(ImportDeclSyntax.self) == true {
      return false
    }
    // If inside an extension with a non-internal explicit ACL, keep it
    if let extensionDecl = nearestEnclosingExtension {
      let extensionACL = extensionDecl.modifiers.first { modifier in
        switch modifier.name.tokenKind {
        case .keyword(.public), .keyword(.package), .keyword(.private), .keyword(.fileprivate),
          .keyword(.internal):
          return true
        default:
          return false
        }
      }
      if let acl = extensionACL, acl.name.tokenKind != .keyword(.internal) {
        return false
      }
    }
    return true
  }

  private var nearestEnclosingExtension: ExtensionDeclSyntax? {
    var current: Syntax? = Syntax(self)
    while let node = current?.parent {
      if let ext = node.as(ExtensionDeclSyntax.self) {
        return ext
      }
      current = node
    }
    return nil
  }
}
