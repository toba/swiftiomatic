import SwiftSyntax

struct EnvironmentEntryRule {
    static let id = "environment_entry"
    static let name = "Environment Entry"
    static let summary = "SwiftUI EnvironmentKey conformances can be replaced with the @Entry macro"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                extension EnvironmentValues {
                  @Entry var screenName: String = "default"
                }
                """,
              )
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓struct ScreenNameKey: EnvironmentKey {
                  static var defaultValue: String { "default" }
                }
                """,
              )
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension EnvironmentEntryRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension EnvironmentEntryRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: StructDeclSyntax) {
      checkEnvironmentKey(
        keyword: node.structKeyword, inheritanceClause: node.inheritanceClause,
        members: node.memberBlock.members)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      checkEnvironmentKey(
        keyword: node.enumKeyword, inheritanceClause: node.inheritanceClause,
        members: node.memberBlock.members)
    }

    private func checkEnvironmentKey(
      keyword: TokenSyntax,
      inheritanceClause: InheritanceClauseSyntax?,
      members: MemberBlockItemListSyntax,
    ) {
      guard let inheritanceClause,
        inheritanceClause.inheritedTypes.contains(where: {
          $0.type.trimmedDescription == "EnvironmentKey"
        })
      else { return }

      // Must have exactly one member: static var defaultValue
      guard members.count == 1,
        let varDecl = members.first?.decl.as(VariableDeclSyntax.self),
        varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
        let binding = varDecl.bindings.first,
        binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "defaultValue"
      else { return }

      violations.append(keyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
