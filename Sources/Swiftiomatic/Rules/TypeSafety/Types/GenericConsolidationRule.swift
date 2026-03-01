import SwiftSyntax

struct GenericConsolidationRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "generic_consolidation",
    name: "Generic Consolidation",
    description:
      "Suggests replacing 'any Protocol' with 'some Protocol' and detecting over-constrained generic parameters",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("func process(_ items: some Sequence) { }"),
      Example("var delegate: any Delegate"),
    ],
    triggeringExamples: [
      Example("func process(_ items: ↓any Collection) { for item in items { } }"),
    ],
  )
}

extension GenericConsolidationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension GenericConsolidationRule: OptInRule {}

extension GenericConsolidationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: TypeAnnotationSyntax) {
      let typeStr = node.type.trimmedDescription

      // Detect `any ProtocolName` in local variable or parameter position
      guard typeStr.hasPrefix("any ") else { return }

      let protocolName = String(typeStr.dropFirst("any ".count))

      // Check if this is in a local/parameter context where `some` would preserve type identity
      let isLocalOrParam =
        node.parent?.is(PatternBindingSyntax.self) == true
        || node.parent?.is(FunctionParameterSyntax.self) == true

      if isLocalOrParam {
        violations.append(
          SyntaxViolation(
            position: node.type.positionAfterSkippingLeadingTrivia,
            reason:
              "'any \(protocolName)' incurs existential overhead — 'some \(protocolName)' preserves type identity",
            severity: .warning,
            confidence: .low,
            suggestion: "some \(protocolName)",
          ),
        )
      }
    }

    override func visitPost(_ node: FunctionParameterSyntax) {
      let typeStr = node.type.trimmedDescription

      // Detect `some Collection` where only Sequence operations are used
      guard typeStr.hasPrefix("some Collection") || typeStr.hasPrefix("some BidirectionalCollection")
        || typeStr.hasPrefix("some RandomAccessCollection")
      else { return }

      // Walk up to the function and check body usage
      guard let funcDecl = findEnclosingFunction(Syntax(node)),
        let body = funcDecl.body
      else { return }

      let paramName = node.secondName?.text ?? node.firstName.text
      let bodyStr = body.statements.trimmedDescription

      // Check if only Sequence-level operations are used
      let collectionOnlyOps = [
        "\(paramName)[", "\(paramName).index", "\(paramName).count",
        "\(paramName).subscript", "\(paramName).startIndex", "\(paramName).endIndex",
      ]
      let usesCollectionOps = collectionOnlyOps.contains { bodyStr.contains($0) }

      if !usesCollectionOps {
        let currentConstraint =
          typeStr.hasPrefix("some Collection")
          ? "Collection" : typeStr.hasPrefix("some BidirectionalCollection")
            ? "BidirectionalCollection" : "RandomAccessCollection"
        violations.append(
          SyntaxViolation(
            position: node.type.positionAfterSkippingLeadingTrivia,
            reason:
              "Parameter '\(paramName)' constrained to \(currentConstraint) but only Sequence operations are used",
            severity: .warning,
            confidence: .low,
            suggestion: "Relax constraint to 'some Sequence' if only iteration is needed",
          ),
        )
      }
    }

    private func findEnclosingFunction(_ node: Syntax) -> FunctionDeclSyntax? {
      var current: Syntax? = node
      while let parent = current?.parent {
        if let funcDecl = parent.as(FunctionDeclSyntax.self) { return funcDecl }
        current = parent
      }
      return nil
    }
  }
}
