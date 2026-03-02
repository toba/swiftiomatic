import SwiftSyntax

struct AccessibilityTraitForButtonRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = AccessibilityTraitForButtonConfiguration()
}

extension AccessibilityTraitForButtonRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AccessibilityTraitForButtonRule {}

extension AccessibilityTraitForButtonRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var isInViewStruct = false

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
      isInViewStruct = node.isViewStruct
      return .visitChildren
    }

    override func visitPost(_: StructDeclSyntax) {
      isInViewStruct = false
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard isInViewStruct, node.isSingleTapGestureModifier() else {
        return
      }

      // The 'node' is the tap gesture modifier itself.
      // Check if this node, any preceding modifiers in the chain, or an encapsulating Button/Link provide
      // exemption.
      if !AccessibilityButtonTraitDeterminator.isExempt(tapGestureNode: node) {
        violations.append(
          SyntaxViolation(
            // Position of .onTapGesture etc.
            position: node.calledExpression.positionAfterSkippingLeadingTrivia,
            reason: AccessibilityTraitForButtonRule.configuration.summary,
            severity: configuration.severity,
          ),
        )
      }
    }
  }
}

private enum AccessibilityButtonTraitDeterminator {
  static let maxSearchDepth = 20  // Limit for traversing up the syntax tree

  static func isExempt(tapGestureNode: FunctionCallExprSyntax) -> Bool {
    // 1. Check if accessibility traits are present anywhere in the same modifier chain
    if hasAccessibilityTraitsInChain(tapGestureNode: tapGestureNode) {
      return true
    }

    // 2. Check if the view (to which the gesture is applied) is part of an inherently exempting container
    return isInsideInherentlyExemptingContainer(startingFrom: tapGestureNode)
  }

  private static func hasAccessibilityTraitsInChain(tapGestureNode: FunctionCallExprSyntax)
    -> Bool
  {
    // Check both directions: before the tap gesture (backwards in chain) and after (ancestors in tree)

    // 1. Check backwards in the modifier chain (modifiers applied before the tap gesture)
    if hasAccessibilityTraitsBackwards(from: tapGestureNode) {
      return true
    }

    // 2. Check forwards by looking at parent nodes (modifiers applied after the tap gesture)
    return hasAccessibilityTraitsForwards(from: tapGestureNode)
  }

  private static func hasAccessibilityTraitsBackwards(from tapGestureNode: FunctionCallExprSyntax)
    -> Bool
  {
    var current: ExprSyntax? = ExprSyntax(tapGestureNode)
    var depth = 0

    while let currentExpr = current, depth < maxSearchDepth {
      defer { depth += 1 }

      if let funcCall = currentExpr.as(FunctionCallExprSyntax.self) {
        // Check if this modifier provides accessibility traits
        if funcCall.providesButtonOrLinkTrait() || funcCall.isAccessibilityHiddenTrue() {
          return true
        }

        // Move to the previous modifier in the chain (the base of the member access)
        if let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self) {
          current = memberAccess.base
        } else {
          // Reached the end of the chain (e.g., Text(...))
          break
        }
      } else {
        break
      }
    }

    return false
  }

  private static func hasAccessibilityTraitsForwards(from tapGestureNode: FunctionCallExprSyntax)
    -> Bool
  {
    // Look at parent nodes to see if accessibility traits are applied after the tap gesture
    var currentNode: Syntax? = Syntax(tapGestureNode).parent
    var depth = 0

    while let node = currentNode, depth < maxSearchDepth {
      defer {
        currentNode = node.parent
        depth += 1
      }

      // Check if this parent node is a function call with accessibility traits
      if let funcCall = node.as(FunctionCallExprSyntax.self) {
        if funcCall.providesButtonOrLinkTrait() || funcCall.isAccessibilityHiddenTrue() {
          return true
        }
      }

      // Stop at certain boundaries
      if node.is(StmtSyntax.self) || node.is(StructDeclSyntax.self) {
        break
      }
    }

    return false
  }

  private static func isInsideInherentlyExemptingContainer(
    startingFrom node: FunctionCallExprSyntax,
  ) -> Bool {
    var currentNode: Syntax? = Syntax(node)
    var depth = 0

    while let currentSyntaxNode = currentNode, depth < maxSearchDepth {
      defer {
        currentNode = currentSyntaxNode.parent
        depth += 1
      }

      if let funcCall = currentSyntaxNode.as(FunctionCallExprSyntax.self),
        let identifier = funcCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName
          .text,
        ["Button", "Link"].contains(identifier)
      {
        return true
      }

      // Stop if we reach a new View declaration or similar boundary
      if currentSyntaxNode.is(StructDeclSyntax.self)
        || currentSyntaxNode
          .is(ClassDeclSyntax.self)
        || currentSyntaxNode.is(EnumDeclSyntax.self)
      {
        break
      }
    }
    return false
  }

  /// Helper to check if an expression (part of a gesture modifier argument) is TapGesture(count: 1) or TapGesture()
  fileprivate static func isSingleTapGestureInstance(expression: ExprSyntax) -> Bool {
    var currentExpr: ExprSyntax? = expression

    // Traverse down if it's a chain of gesture modifiers like .onEnded to find the base gesture.
    while let memberCall = currentExpr?
      .as(FunctionCallExprSyntax.self),  // e.g. TapGesture().onEnded()
      let memberAccess = memberCall.calledExpression.as(MemberAccessExprSyntax.self),
      memberAccess.base != nil
    {  // Ensure it's a chain like x.method()
      currentExpr = memberAccess.base
    }

    guard let gestureCall = currentExpr?.as(FunctionCallExprSyntax.self),
      let gestureName = gestureCall.calledExpression.as(DeclReferenceExprSyntax.self)?
        .baseName
        .text,
      gestureName == "TapGesture"
    else {
      return false
    }

    // Check count argument: TapGesture() or TapGesture(count: 1)
    if gestureCall.arguments.isEmpty { return true }  // Default count is 1

    if let countArg = gestureCall.arguments.first(where: { $0.label?.text == "count" }) {
      return countArg.expression.as(IntegerLiteralExprSyntax.self)?.literal.text == "1"
    }

    // If 'count' is not specified, it defaults to 1.
    return !gestureCall.arguments.contains(where: { $0.label?.text == "count" })
  }
}

extension StructDeclSyntax {
  fileprivate var isViewStruct: Bool {
    guard let inheritanceClause else { return false }
    return inheritanceClause.inheritedTypes.contains { inheritedType in
      inheritedType.type.as(IdentifierTypeSyntax.self)?.name.text == "View"
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate func isSingleTapGestureModifier() -> Bool {
    guard let calledExpr = calledExpression.as(MemberAccessExprSyntax.self)
    else { return false }
    let name = calledExpr.declName.baseName.text

    if name == "onTapGesture" {
      if arguments.isEmpty { return true }  // Default count is 1
      if let countArg = arguments.first(where: { $0.label?.text == "count" }) {
        return countArg.expression.as(IntegerLiteralExprSyntax.self)?.literal.text == "1"
      }
      // If 'count' is not specified, it defaults to 1 (other args like 'perform' might be present)
      return !arguments.contains(where: { $0.label?.text == "count" })
    }

    if ["gesture", "simultaneousGesture", "highPriorityGesture"].contains(name) {
      guard let firstArgExpression = arguments.first?.expression else { return false }
      return AccessibilityButtonTraitDeterminator.isSingleTapGestureInstance(
        expression: firstArgExpression,
      )
    }
    return false
  }

  fileprivate func providesButtonOrLinkTrait() -> Bool {
    guard let calledExpr = calledExpression.as(MemberAccessExprSyntax.self)
    else { return false }
    let name = calledExpr.declName.baseName.text

    if name == "accessibilityAddTraits" {
      guard let firstArgExpr = arguments.first?.expression else { return false }
      return Self.expressionContainsButtonOrLinkTrait(firstArgExpr)
    }

    if name == "accessibility" {
      guard let addTraitsArg = arguments.first(where: { $0.label?.text == "addTraits" })
      else {
        return false
      }
      return Self.expressionContainsButtonOrLinkTrait(addTraitsArg.expression)
    }

    return false
  }

  private static func expressionContainsButtonOrLinkTrait(_ expression: ExprSyntax) -> Bool {
    if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
      let traitName = memberAccess.declName.baseName.text
      return traitName == "isButton" || traitName == "isLink"
    }
    if let arrayExpr = expression.as(ArrayExprSyntax.self) {
      return arrayExpr.elements.contains { element in
        self.expressionContainsButtonOrLinkTrait(element.expression)
      }
    }
    return false
  }

  fileprivate func isAccessibilityHiddenTrue() -> Bool {
    guard let calledExpr = calledExpression.as(MemberAccessExprSyntax.self)
    else { return false }
    let name = calledExpr.declName.baseName.text

    if name == "accessibilityHidden" {
      return arguments.first?.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind
        == .keyword(.true)
    }

    if name == "accessibility" {
      guard let hiddenArg = arguments.first(where: { $0.label?.text == "hidden" }) else {
        return false
      }
      return hiddenArg.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind
        == .keyword(.true)
    }

    return false
  }
}
