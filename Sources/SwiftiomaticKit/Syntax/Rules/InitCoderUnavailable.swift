import SwiftSyntax

/// Add `@available(*, unavailable)` to `required init(coder:)` that only calls `fatalError`.
///
/// When a `UIView` or `UIViewController` subclass provides a `required init(coder:)` that
/// immediately calls `fatalError`, it should be marked `@available(*, unavailable)` so the
/// compiler prevents it from being called.
///
/// Lint: A `required init(coder:)` stub without `@available(*, unavailable)` yields a warning.
///
/// Format: The `@available(*, unavailable)` attribute is added.
final class InitCoderUnavailable: RewriteSyntaxRule {
  override class var defaultHandling: RuleHandling { .off }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    guard isCoderInitStub(node), !hasUnavailableAttribute(node) else {
      return DeclSyntax(node)
    }

    diagnose(.addUnavailableToInitCoder, on: node.initKeyword)

    var result = node

    // Build @available(*, unavailable)
    let attribute = AttributeSyntax(
      atSign: .atSignToken(),
      attributeName: IdentifierTypeSyntax(name: .identifier("available")),
      leftParen: .leftParenToken(),
      arguments: .availability(
        AvailabilityArgumentListSyntax([
          AvailabilityArgumentSyntax(
            argument: .token(.binaryOperator("*")),
            trailingComma: .commaToken(trailingTrivia: .space)
          ),
          AvailabilityArgumentSyntax(
            argument: .token(.keyword(.unavailable))
          ),
        ])
      ),
      rightParen: .rightParenToken()
    )

    // Prepend the attribute. Copy leading trivia (newline + indentation) from the first
    // existing element. The existing element keeps its trivia so both lines are indented equally.
    var newAttribute = AttributeListSyntax.Element.attribute(attribute)
    if let firstAttr = result.attributes.first {
      newAttribute.leadingTrivia = firstAttr.leadingTrivia
    } else if let firstModifier = result.modifiers.first {
      newAttribute.leadingTrivia = firstModifier.leadingTrivia
    } else {
      newAttribute.leadingTrivia = result.initKeyword.leadingTrivia
    }
    newAttribute.trailingTrivia = []

    result.attributes.insert(newAttribute, at: result.attributes.startIndex)

    return DeclSyntax(result)
  }

  /// Returns `true` if this is a `required init(coder: NSCoder)` whose body only calls
  /// `fatalError(...)`.
  private func isCoderInitStub(_ node: InitializerDeclSyntax) -> Bool {
    // Must have `required` modifier.
    guard node.modifiers.contains(where: {
      $0.name.tokenKind == .keyword(.required)
    }) else { return false }

    // Must have exactly one parameter with type NSCoder.
    let params = node.signature.parameterClause.parameters
    guard params.count == 1, let param = params.first else { return false }
    guard let type = param.type.as(IdentifierTypeSyntax.self),
      type.name.text == "NSCoder"
    else { return false }

    // Body must have exactly one statement that calls fatalError.
    guard let body = node.body,
      body.statements.count == 1,
      let statement = body.statements.first
    else { return false }

    // The statement must be a fatalError call.
    if let funcCall = statement.item.as(FunctionCallExprSyntax.self),
      let callee = funcCall.calledExpression.as(DeclReferenceExprSyntax.self),
      callee.baseName.text == "fatalError"
    {
      return true
    }

    return false
  }

  /// Returns `true` if the initializer already has `@available(*, unavailable)`.
  private func hasUnavailableAttribute(_ node: InitializerDeclSyntax) -> Bool {
    node.attributes.contains { element in
      guard let attr = element.as(AttributeSyntax.self),
        let name = attr.attributeName.as(IdentifierTypeSyntax.self),
        name.name.text == "available",
        case .availability(let args) = attr.arguments
      else { return false }

      return args.contains { arg in
        if case .token(let token) = arg.argument {
          return token.tokenKind == .keyword(.unavailable)
        }
        if case .availabilityLabeledArgument(let labeled) = arg.argument {
          return labeled.label.tokenKind == .keyword(.unavailable)
        }
        return false
      }
    }
  }
}

extension Finding.Message {
  fileprivate static let addUnavailableToInitCoder: Finding.Message =
    "add '@available(*, unavailable)' to this 'required init(coder:)' stub"
}
