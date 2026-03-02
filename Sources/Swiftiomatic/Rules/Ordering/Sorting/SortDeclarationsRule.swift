import Foundation
import SwiftSyntax

struct SortDeclarationsRule {
    static let id = "sort_declarations"
    static let name = "Sort Declarations"
    static let summary = "Declarations marked with `// sm:sort` should have their members sorted alphabetically"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                // sm:sort
                enum FeatureFlags {
                  case barFeature
                  case fooFeature
                }
                """,
              )
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                // sm:sort
                enum ↓FeatureFlags {
                  case fooFeature
                  case barFeature
                }
                """,
              )
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension SortDeclarationsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SortDeclarationsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumDeclSyntax) {
      guard hasSortDirective(node.leadingTrivia) else { return }
      checkSorted(
        members: node.memberBlock.members, at: node.name.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      guard hasSortDirective(node.leadingTrivia) else { return }
      checkSorted(
        members: node.memberBlock.members, at: node.name.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      guard hasSortDirective(node.leadingTrivia) else { return }
      checkSorted(
        members: node.memberBlock.members, at: node.name.positionAfterSkippingLeadingTrivia)
    }

    private func hasSortDirective(_ trivia: Trivia) -> Bool {
      for piece in trivia {
        if case .lineComment(let text) = piece, text.contains("sm:sort") {
          return true
        }
      }
      return false
    }

    private func checkSorted(members: MemberBlockItemListSyntax, at position: AbsolutePosition) {
      let names = members.compactMap { member -> String? in
        if let enumCase = member.decl.as(EnumCaseDeclSyntax.self) {
          return enumCase.elements.first?.name.text
        }
        if let varDecl = member.decl.as(VariableDeclSyntax.self) {
          return varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }
        if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
          return funcDecl.name.text
        }
        return nil
      }

      let sorted = names.sorted { $0.localizedCompare($1) == .orderedAscending }
      if names != sorted {
        violations.append(position)
      }
    }
  }
}
