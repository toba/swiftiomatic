import SwiftSyntax

struct EnvironmentEntryRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "environment_entry",
    name: "Environment Entry",
    description: "SwiftUI EnvironmentKey conformances can be replaced with the @Entry macro",
    scope: .suggest,
    minSwiftVersion: .v6,
    nonTriggeringExamples: [
      Example(
        """
        extension EnvironmentValues {
          @Entry var screenName: String = "default"
        }
        """,
      )
    ],
    triggeringExamples: [
      Example(
        """
        ↓struct ScreenNameKey: EnvironmentKey {
          static var defaultValue: String { "default" }
        }
        """,
      )
    ],
  )
}

extension EnvironmentEntryRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension EnvironmentEntryRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
