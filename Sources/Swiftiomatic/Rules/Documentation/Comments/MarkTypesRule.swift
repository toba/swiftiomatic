import SwiftSyntax

struct MarkTypesRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "mark_types",
    name: "Mark Types",
    description: "Top-level types and extensions should have MARK comments for organization",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        // MARK: - Foo
        class Foo {}
        """,
      ),
      Example(
        """
        import Foundation
        struct Foo {}
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        ↓class Foo {}
        class Bar {}
        """,
      )
    ],
  )
}

extension MarkTypesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MarkTypesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SourceFileSyntax) {
      // Collect top-level type declarations (excluding imports)
      let typeDecls = node.statements.compactMap { stmt -> (TokenSyntax, Trivia)? in
        if let classDecl = stmt.item.as(ClassDeclSyntax.self) {
          return (classDecl.classKeyword, classDecl.leadingTrivia)
        }
        if let structDecl = stmt.item.as(StructDeclSyntax.self) {
          return (structDecl.structKeyword, structDecl.leadingTrivia)
        }
        if let enumDecl = stmt.item.as(EnumDeclSyntax.self) {
          return (enumDecl.enumKeyword, enumDecl.leadingTrivia)
        }
        if let extensionDecl = stmt.item.as(ExtensionDeclSyntax.self) {
          return (extensionDecl.extensionKeyword, extensionDecl.leadingTrivia)
        }
        if let protocolDecl = stmt.item.as(ProtocolDeclSyntax.self) {
          return (protocolDecl.protocolKeyword, protocolDecl.leadingTrivia)
        }
        return nil
      }

      // Only flag if there are multiple top-level types
      guard typeDecls.count > 1 else { return }

      for (keyword, trivia) in typeDecls {
        let hasMarkComment = trivia.contains(where: { piece in
          if case .lineComment(let text) = piece {
            return text.contains("MARK:")
          }
          return false
        })

        if !hasMarkComment {
          violations.append(keyword.positionAfterSkippingLeadingTrivia)
        }
      }
    }
  }
}
