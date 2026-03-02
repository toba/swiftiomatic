import Foundation
import SwiftSyntax

struct TypeNameRule {
  var options = TypeNameOptions()

  static let configuration = TypeNameConfiguration()
}

extension TypeNameRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension TypeNameRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: StructDeclSyntax) {
      if let violation = violation(
        identifier: node.name, modifiers: node.modifiers,
        inheritedTypes: node.inheritanceClause?.inheritedTypes,
      ) {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      if let violation = violation(
        identifier: node.name, modifiers: node.modifiers,
        inheritedTypes: node.inheritanceClause?.inheritedTypes,
      ) {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      if let violation = violation(
        identifier: node.name, modifiers: node.modifiers, inheritedTypes: nil,
      ) {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: AssociatedTypeDeclSyntax) {
      if let violation = violation(
        identifier: node.name, modifiers: node.modifiers,
        inheritedTypes: node.inheritanceClause?.inheritedTypes,
      ) {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      if let violation = violation(
        identifier: node.name, modifiers: node.modifiers,
        inheritedTypes: node.inheritanceClause?.inheritedTypes,
      ) {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: ActorDeclSyntax) {
      if let violation = violation(
        identifier: node.name, modifiers: node.modifiers,
        inheritedTypes: node.inheritanceClause?.inheritedTypes,
      ) {
        violations.append(violation)
      }
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      if configuration.validateProtocols,
        let violation = violation(
          identifier: node.name, modifiers: node.modifiers,
          inheritedTypes: node.inheritanceClause?.inheritedTypes,
        )
      {
        violations.append(violation)
      }
    }

    private func violation(
      identifier: TokenSyntax,
      modifiers: DeclModifierListSyntax,
      inheritedTypes: InheritedTypeListSyntax?,
    ) -> SyntaxViolation? {
      let originalName = identifier.text
      let nameConfiguration = configuration.nameConfiguration

      guard !nameConfiguration.shouldExclude(name: originalName) else { return nil }

      let name =
        originalName
        .strippingBackticks()
        .strippingLeadingUnderscore(ifPrivate: modifiers.containsPrivateOrFileprivate())
        .strippingTrailingSwiftUIPreviewProvider(inheritedTypes: inheritedTypes)
      if !nameConfiguration.containsOnlyAllowedCharacters(name: name) {
        return SyntaxViolation(
          position: identifier.positionAfterSkippingLeadingTrivia,
          reason:
            "Type name '\(name)' should only contain alphanumeric and other allowed characters",
          severity: nameConfiguration.unallowedSymbolsSeverity.severity,
        )
      }
      if let caseCheckSeverity = nameConfiguration.validatesStartWithLowercase.severity,
        name.first?.isLowercase == true
      {
        return SyntaxViolation(
          position: identifier.positionAfterSkippingLeadingTrivia,
          reason: "Type name '\(name)' should start with an uppercase character",
          severity: caseCheckSeverity,
        )
      }
      if let severity = nameConfiguration.severity(forLength: name.count) {
        return SyntaxViolation(
          position: identifier.positionAfterSkippingLeadingTrivia,
          reason:
            "Type name '\(name)' should be between \(nameConfiguration.minLengthThreshold) and "
            + "\(nameConfiguration.maxLengthThreshold) characters long",
          severity: severity,
        )
      }

      return nil
    }
  }
}

extension String {
  fileprivate func strippingBackticks() -> String {
    replacingOccurrences(of: "`", with: "")
  }

  fileprivate func strippingTrailingSwiftUIPreviewProvider(inheritedTypes: InheritedTypeListSyntax?)
    -> String
  {
    guard let inheritedTypes,
      hasSuffix("_Previews"),
      let lastPreviewsIndex = lastIndex(of: "_Previews"),
      inheritedTypes.typeNames.contains("PreviewProvider")
    else {
      return self
    }

    return substring(from: 0, length: lastPreviewsIndex)
  }

  func strippingLeadingUnderscore(ifPrivate isPrivate: Bool) -> String {
    isPrivate && first == "_" ? String(self[index(after: startIndex)...]) : self
  }
}

extension InheritedTypeListSyntax {
  fileprivate var typeNames: Set<String> {
    Set(compactMap { $0.type.as(IdentifierTypeSyntax.self) }.map(\.name.text))
  }
}
