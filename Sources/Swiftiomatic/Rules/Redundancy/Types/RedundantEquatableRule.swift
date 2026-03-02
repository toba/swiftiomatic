import SwiftSyntax

struct RedundantEquatableRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantEquatableConfiguration()
}

extension RedundantEquatableRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantEquatableRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: StructDeclSyntax) {
      // Must conform to Equatable
      guard let inheritanceClause = node.inheritanceClause,
        inheritanceClause.inheritedTypes.contains(where: {
          $0.type.trimmedDescription == "Equatable"
        })
      else { return }

      // Find manual == implementation
      for member in node.memberBlock.members {
        guard let funcDecl = member.decl.as(FunctionDeclSyntax.self),
          funcDecl.name.text == "==",
          funcDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
        else { continue }

        violations.append(funcDecl.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
