import SwiftSyntax

struct RedundantTypeAnnotationRule {
  var options = RedundantTypeAnnotationOptions()

  static let configuration = RedundantTypeAnnotationConfiguration()
}

extension RedundantTypeAnnotationRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantTypeAnnotationRule {}

extension RedundantTypeAnnotationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: PatternBindingSyntax) {
      if let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self),
        !configuration.shouldSkipRuleCheck(for: varDecl),
        let typeAnnotation = node.typeAnnotation,
        let initializer = node.initializer?.value
      {
        collectViolation(forType: typeAnnotation, withInitializer: initializer)
      }
    }

    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      if let typeAnnotation = node.typeAnnotation,
        let initializer = node.initializer?.value
      {
        collectViolation(forType: typeAnnotation, withInitializer: initializer)
      }
    }

    private func collectViolation(
      forType type: TypeAnnotationSyntax, withInitializer initializer: ExprSyntax,
    ) {
      let validateLiterals = configuration.considerDefaultLiteralTypesRedundant
      let isLiteralRedundant =
        validateLiterals
        && initializer
          .hasRedundant(literalType: type.type)
      guard isLiteralRedundant || initializer.hasRedundant(type: type.type) else {
        return
      }
      violations.append(
        at: type.positionAfterSkippingLeadingTrivia,
        correction: .init(
          start: type.position,
          end: type.endPositionBeforeTrailingTrivia,
          replacement: "",
        ),
      )
    }
  }
}

extension ExprSyntax {
  /// An expression can represent an access to an identifier in one or another way depending on the exact underlying
  /// expression type. E.g. the expression `A` accesses `A` while `f()` accesses `f` and `a.b.c` accesses `a` in the
  /// sense of this property. In the context of this rule, `Set<Int>()` accesses `Set` as well as `Set<Int>`.
  fileprivate var accessedNames: [String] {
    if let declRef = `as`(DeclReferenceExprSyntax.self) {
      [declRef.trimmedDescription]
    } else if let memberAccess = `as`(MemberAccessExprSyntax.self) {
      (memberAccess.base?.accessedNames ?? []) + [memberAccess.trimmedDescription]
    } else if let genericSpecialization = `as`(GenericSpecializationExprSyntax.self) {
      [genericSpecialization.trimmedDescription]
        + genericSpecialization.expression
        .accessedNames
    } else if let call = `as`(FunctionCallExprSyntax.self) {
      call.calledExpression.accessedNames
    } else if let arrayExpr = `as`(ArrayExprSyntax.self) {
      [arrayExpr.trimmedDescription]
    } else {
      []
    }
  }

  fileprivate func hasRedundant(literalType type: TypeSyntax) -> Bool {
    type.trimmedDescription == kind.compilerInferredLiteralType
  }

  fileprivate func hasRedundant(type: TypeSyntax) -> Bool {
    `as`(ForceUnwrapExprSyntax.self)?.expression.hasRedundant(type: type)
      ?? accessedNames.contains(type.trimmedDescription)
  }
}

extension SyntaxKind {
  fileprivate var compilerInferredLiteralType: String? {
    switch self {
    case .booleanLiteralExpr:
      "Bool"
    case .floatLiteralExpr:
      "Double"
    case .integerLiteralExpr:
      "Int"
    case .stringLiteralExpr:
      "String"
    default:
      nil
    }
  }
}

extension RedundantTypeAnnotationOptions {
  func shouldSkipRuleCheck(for varDecl: VariableDeclSyntax) -> Bool {
    if ignoreAttributes.contains(where: { varDecl.attributes.contains(attributeNamed: $0) }) {
      return true
    }

    return ignoreProperties && varDecl.parent?.is(MemberBlockItemSyntax.self) == true
  }
}
