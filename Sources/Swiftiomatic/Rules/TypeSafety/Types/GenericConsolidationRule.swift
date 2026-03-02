import SwiftSyntax

struct GenericConsolidationRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = GenericConsolidationConfiguration()
}

extension GenericConsolidationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension GenericConsolidationRule {}

extension GenericConsolidationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
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
      guard
        typeStr.hasPrefix("some Collection") || typeStr.hasPrefix("some BidirectionalCollection")
          || typeStr.hasPrefix("some RandomAccessCollection")
      else { return }

      // Walk up to the function and check body usage
      guard let funcDecl = node.nearestAncestor(ofType: FunctionDeclSyntax.self),
        let body = funcDecl.body
      else { return }

      let paramName = node.secondName?.text ?? node.firstName.text

      // Check if Collection-specific operations are used via AST walk
      let walker = CollectionOpWalker(paramName: paramName, viewMode: .sourceAccurate)
      walker.walk(body)
      let usesCollectionOps = walker.found

      if !usesCollectionOps {
        let currentConstraint =
          typeStr.hasPrefix("some Collection")
          ? "Collection"
          : typeStr.hasPrefix("some BidirectionalCollection")
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
  }
}

private final class CollectionOpWalker: SyntaxVisitor {
  let paramName: String
  var found = false

  private static let collectionMembers: Set<String> = [
    "index", "count", "subscript", "startIndex", "endIndex",
  ]

  init(paramName: String, viewMode: SyntaxTreeViewMode) {
    self.paramName = paramName
    super.init(viewMode: viewMode)
  }

  override func visit(_ node: SubscriptCallExprSyntax) -> SyntaxVisitorContinueKind {
    if node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == paramName {
      found = true
      return .skipChildren
    }
    return .visitChildren
  }

  override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
    if node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == paramName,
      Self.collectionMembers.contains(node.declName.baseName.text)
    {
      found = true
      return .skipChildren
    }
    return .visitChildren
  }
}
