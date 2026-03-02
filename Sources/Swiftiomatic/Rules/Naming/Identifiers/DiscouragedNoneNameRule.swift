import SwiftSyntax

struct DiscouragedNoneNameRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = DiscouragedNoneNameConfiguration()
}

extension DiscouragedNoneNameRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedNoneNameRule {}

extension DiscouragedNoneNameRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumCaseElementSyntax) {
      let emptyParams = node.parameterClause?.parameters.isEmpty ?? true
      if emptyParams, node.name.isNone {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: reason(type: "`case`"),
          ),
        )
      }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      let type: String? = {
        if node.modifiers.contains(keyword: .class) {
          return "`class` member"
        }
        if node.modifiers.contains(keyword: .static) {
          return "`static` member"
        }
        return nil
      }()

      guard let type else {
        return
      }

      for binding in node.bindings {
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          pattern.identifier.isNone
        else {
          continue
        }

        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: reason(type: type),
          ),
        )
        return
      }
    }

    private func reason(type: String) -> String {
      let reason =
        "Avoid naming \(type) `none` as the compiler can think you mean `Optional<T>.none`"
      let recommendation = "consider using an Optional value instead"
      return "\(reason); \(recommendation)"
    }
  }
}

extension TokenSyntax {
  fileprivate var isNone: Bool {
    tokenKind == .identifier("none") || tokenKind == .identifier("`none`")
  }
}
