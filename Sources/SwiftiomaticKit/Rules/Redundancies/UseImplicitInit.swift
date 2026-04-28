import SwiftSyntax

/// Prefer implicit member syntax when the type is known from context.
///
/// When a return type, type annotation, or parameter type makes the expected type clear,
/// explicit type references in constructor calls and static member accesses are redundant.
///
/// ```swift
/// // Before
/// static var defaultValue: Bar { Bar(x: 1) }
/// func make() -> Config { Config(debug: true) }
/// func run(mode: Mode = Mode.fast) {}
///
/// // After
/// static var defaultValue: Bar { .init(x: 1) }
/// func make() -> Config { .init(debug: true) }
/// func run(mode: Mode = .fast) {}
/// ```
///
/// Lint: A lint warning is raised when an explicit type can be replaced with implicit member syntax.
///
/// Rewrite: The explicit type is replaced with a leading dot.
final class UseImplicitInit: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  // MARK: - Computed properties and stored properties with type annotations

  override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    Self.transform(node, parent: Syntax(node).parent, context: context)
  }

  static func transform(
    _ node: PatternBindingSyntax,
    parent: Syntax?,
    context: Context
  ) -> PatternBindingSyntax {
    // Case 1: Stored property with type annotation and initializer
    // `let config: Config = Config(debug: true)` → `let config: Config = .init(debug: true)`
    if let typeAnnotation = node.typeAnnotation,
      let initializer = node.initializer
    {
      let typeName = typeAnnotation.type.trimmedDescription
      if let rewritten = rewriteExpression(initializer.value, matchingType: typeName, context: context) {
        var result = node
        var newInitializer = initializer
        newInitializer.value = rewritten
        result.initializer = newInitializer
        return result
      }
    }

    // Case 2: Computed property with type annotation and accessor body
    // `var value: Bar { Bar(x: 1) }` → `var value: Bar { .init(x: 1) }`
    if let typeAnnotation = node.typeAnnotation,
      let accessorBlock = node.accessorBlock
    {
      let typeName = typeAnnotation.type.trimmedDescription

      switch accessorBlock.accessors {
      case .getter(let body):
        if let rewritten = rewriteCodeBlockItems(body, matchingType: typeName, context: context) {
          var result = node
          var newAccessorBlock = accessorBlock
          newAccessorBlock.accessors = .getter(rewritten)
          result.accessorBlock = newAccessorBlock
          return result
        }

      case .accessors(let accessorList):
        var newAccessors = accessorList
        var didChange = false
        for (index, accessor) in accessorList.enumerated() {
          guard accessor.accessorSpecifier.tokenKind == .keyword(.get),
            let body = accessor.body
          else { continue }
          if let rewritten = rewriteCodeBlockItems(body.statements, matchingType: typeName, context: context) {
            var newAccessor = accessor
            var newBody = body
            newBody.statements = rewritten
            newAccessor.body = newBody
            newAccessors = newAccessors.with(
              \.[newAccessors.index(newAccessors.startIndex, offsetBy: index)], newAccessor)
            didChange = true
          }
        }
        if didChange {
          var result = node
          var newAccessorBlock = accessorBlock
          newAccessorBlock.accessors = .accessors(newAccessors)
          result.accessorBlock = newAccessorBlock
          return result
        }
      }
    }

    return node
  }

  // MARK: - Function / method return types and default parameter values

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    Self.transform(node, parent: Syntax(node).parent, context: context)
  }

  static func transform(
    _ node: FunctionDeclSyntax,
    parent: Syntax?,
    context: Context
  ) -> DeclSyntax {
    var result = node
    var didChange = false

    // Rewrite default parameter values
    if let rewrittenParams = rewriteParameterDefaults(node.signature.parameterClause, context: context) {
      var newSignature = result.signature
      newSignature.parameterClause = rewrittenParams
      result.signature = newSignature
      didChange = true
    }

    // Rewrite return expression
    if let returnType = result.signature.returnClause?.type.trimmedDescription,
      let body = result.body,
      let rewritten = rewriteCodeBlockItems(body.statements, matchingType: returnType, context: context)
    {
      var newBody = body
      newBody.statements = rewritten
      result.body = newBody
      didChange = true
    }

    guard didChange else { return DeclSyntax(node) }
    return DeclSyntax(result)
  }

  // MARK: - Initializer default parameter values

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    Self.transform(node, parent: Syntax(node).parent, context: context)
  }

  static func transform(
    _ node: InitializerDeclSyntax,
    parent: Syntax?,
    context: Context
  ) -> DeclSyntax {
    guard let rewrittenParams = rewriteParameterDefaults(node.signature.parameterClause, context: context) else {
      return DeclSyntax(node)
    }
    var result = node
    var newSignature = node.signature
    newSignature.parameterClause = rewrittenParams
    result.signature = newSignature
    return DeclSyntax(result)
  }

  // MARK: - Subscript return types

  override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    Self.transform(node, parent: Syntax(node).parent, context: context)
  }

  static func transform(
    _ node: SubscriptDeclSyntax,
    parent: Syntax?,
    context: Context
  ) -> DeclSyntax {
    guard let accessorBlock = node.accessorBlock else {
      return DeclSyntax(node)
    }

    let typeName = node.returnClause.type.trimmedDescription

    switch accessorBlock.accessors {
    case .getter(let body):
      if let rewritten = rewriteCodeBlockItems(body, matchingType: typeName, context: context) {
        var result = node
        var newAccessorBlock = accessorBlock
        newAccessorBlock.accessors = .getter(rewritten)
        result.accessorBlock = newAccessorBlock
        return DeclSyntax(result)
      }

    case .accessors(let accessorList):
      var newAccessors = accessorList
      var didChange = false
      for (index, accessor) in accessorList.enumerated() {
        guard accessor.accessorSpecifier.tokenKind == .keyword(.get),
          let body = accessor.body
        else { continue }
        if let rewritten = rewriteCodeBlockItems(body.statements, matchingType: typeName, context: context) {
          var newAccessor = accessor
          var newBody = body
          newBody.statements = rewritten
          newAccessor.body = newBody
          newAccessors = newAccessors.with(
            \.[newAccessors.index(newAccessors.startIndex, offsetBy: index)], newAccessor)
          didChange = true
        }
      }
      if didChange {
        var result = node
        var newAccessorBlock = accessorBlock
        newAccessorBlock.accessors = .accessors(newAccessors)
        result.accessorBlock = newAccessorBlock
        return DeclSyntax(result)
      }
    }

    return DeclSyntax(node)
  }

  // MARK: - Default parameter values

  /// Rewrites default parameter values in a parameter clause.
  private static func rewriteParameterDefaults(
    _ clause: FunctionParameterClauseSyntax,
    context: Context
  ) -> FunctionParameterClauseSyntax? {
    var params = clause.parameters
    var didChange = false

    for (index, param) in params.enumerated() {
      guard let defaultValue = param.defaultValue else { continue }
      let typeName = param.type.trimmedDescription
      guard let rewritten = rewriteExpression(defaultValue.value, matchingType: typeName, context: context) else {
        continue
      }

      var newParam = param
      var newDefault = defaultValue
      newDefault.value = rewritten
      newParam.defaultValue = newDefault
      params = params.with(
        \.[params.index(params.startIndex, offsetBy: index)], newParam)
      didChange = true
    }

    guard didChange else { return nil }
    var result = clause
    result.parameters = params
    return result
  }

  // MARK: - Rewriting helpers

  /// Rewrites the last expression in a code block item list if it matches the type.
  /// Handles both implicit returns (single expression) and explicit `return` statements.
  private static func rewriteCodeBlockItems(
    _ items: CodeBlockItemListSyntax, matchingType typeName: String, context: Context
  ) -> CodeBlockItemListSyntax? {
    guard let lastItem = items.last else { return nil }

    // Extract the expression from the last item, unwrapping ExpressionStmtSyntax if needed.
    if let expr = expressionFromItem(lastItem) {
      if let rewritten = rewriteExpression(expr, matchingType: typeName, context: context) {
        var newItem = lastItem
        if let exprStmt = lastItem.item.as(ExpressionStmtSyntax.self) {
          var newExprStmt = exprStmt
          newExprStmt.expression = rewritten
          newItem.item = .init(StmtSyntax(newExprStmt))
        } else {
          newItem.item = .init(rewritten)
        }
        return items.with(\.[items.index(before: items.endIndex)], newItem)
      }
    }

    // Explicit return statement
    if let returnStmt = lastItem.item.as(ReturnStmtSyntax.self),
      let expr = returnStmt.expression
    {
      if let rewritten = rewriteExpression(expr, matchingType: typeName, context: context) {
        var newReturn = returnStmt
        newReturn.expression = rewritten
        var newItem = lastItem
        newItem.item = .init(newReturn)
        return items.with(\.[items.index(before: items.endIndex)], newItem)
      }
    }

    return nil
  }

  /// Unwraps `ExpressionStmtSyntax` to get the underlying expression.
  private static func expressionFromItem(_ item: CodeBlockItemSyntax) -> ExprSyntax? {
    if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
      return exprStmt.expression
    }
    return item.item.as(ExprSyntax.self)
  }

  /// Attempts to rewrite an expression by replacing an explicit type with implicit member syntax.
  /// Returns `nil` if no rewrite applies.
  private static func rewriteExpression(
    _ expr: ExprSyntax, matchingType typeName: String, context: Context
  ) -> ExprSyntax? {
    // Case A: `Type(args)` → `.init(args)` — constructor call
    if let funcCall = expr.as(FunctionCallExprSyntax.self) {
      return rewriteFunctionCall(funcCall, matchingType: typeName, context: context)
    }

    // Case B: `Type.member` → `.member` — static member access (no call)
    if let memberAccess = expr.as(MemberAccessExprSyntax.self) {
      return rewriteMemberAccess(memberAccess, matchingType: typeName, context: context)
    }

    return nil
  }

  /// Rewrites `Type(args)` → `.init(args)` or `Type.factory(args)` → `.factory(args)`.
  private static func rewriteFunctionCall(
    _ call: FunctionCallExprSyntax, matchingType typeName: String, context: Context
  ) -> ExprSyntax? {
    let calledExpr = call.calledExpression

    // Skip single-unlabeled-argument calls. These are conversion / type-erasure
    // patterns (`DeclSyntax(node)`, `String(buffer)`, `CodeBlockItemListSyntax(items)`)
    // rather than field-init patterns (`Foo(x: 1, y: 2)`). Rewriting them to
    // `.init(arg)` obscures the type-erasure intent and can break type
    // inference at the use site (the generic init may not resolve from
    // contextual return type alone).
    if call.arguments.count == 1, call.arguments.first?.label == nil {
      return nil
    }

    // `Type(args)` — direct constructor call
    if let declRef = calledExpr.as(DeclReferenceExprSyntax.self),
      declRef.argumentNames == nil,
      declRef.baseName.text == typeName
    {
      let original = call.trimmedDescription
      Self.diagnose(.useImplicitInit(original: original, replacement: dotInitDescription(call)), on: declRef, context: context)

      // Build `.init(args)` — MemberAccessExpr with no base
      let dotInit = MemberAccessExprSyntax(
        leadingTrivia: declRef.leadingTrivia,
        period: .periodToken(),
        declName: DeclReferenceExprSyntax(baseName: .keyword(.`init`))
      )
      var newCall = call
      newCall.calledExpression = ExprSyntax(dotInit)
      return ExprSyntax(newCall)
    }

    // `Type<Generic>(args)` — generic constructor
    if let generic = calledExpr.as(GenericSpecializationExprSyntax.self),
      generic.trimmedDescription == typeName
    {
      let original = call.trimmedDescription
      Self.diagnose(.useImplicitInit(original: original, replacement: dotInitDescription(call)), on: generic, context: context)

      let dotInit = MemberAccessExprSyntax(
        leadingTrivia: generic.leadingTrivia,
        period: .periodToken(),
        declName: DeclReferenceExprSyntax(baseName: .keyword(.`init`))
      )
      var newCall = call
      newCall.calledExpression = ExprSyntax(dotInit)
      return ExprSyntax(newCall)
    }

    // `Type.factory(args)` — static factory call
    if let memberAccess = calledExpr.as(MemberAccessExprSyntax.self),
      let base = memberAccess.base,
      baseMatchesType(base, typeName: typeName),
      memberAccess.declName.baseName.tokenKind != .keyword(.`init`)
    {
      let original = call.trimmedDescription
      // Build `.factory(args)`
      var newMemberAccess = memberAccess
      newMemberAccess.leadingTrivia = memberAccess.base?.leadingTrivia ?? memberAccess.leadingTrivia
      newMemberAccess.base = nil

      Self.diagnose(
        .useImplicitInit(
          original: original,
          replacement: rewrittenCallDescription(call, newCalledExpression: ExprSyntax(newMemberAccess))
        ),
        on: base,
        context: context
      )

      var newCall = call
      newCall.calledExpression = ExprSyntax(newMemberAccess)
      return ExprSyntax(newCall)
    }

    return nil
  }

  /// Rewrites `Type.member` → `.member` (static property access, no function call).
  private static func rewriteMemberAccess(
    _ memberAccess: MemberAccessExprSyntax, matchingType typeName: String, context: Context
  ) -> ExprSyntax? {
    guard let base = memberAccess.base,
      baseMatchesType(base, typeName: typeName),
      memberAccess.declName.baseName.tokenKind != .keyword(.`init`)
    else {
      return nil
    }

    let original = memberAccess.trimmedDescription
    var newMemberAccess = memberAccess
    newMemberAccess.leadingTrivia = base.leadingTrivia
    newMemberAccess.base = nil
    let replacement = newMemberAccess.trimmedDescription

    Self.diagnose(.useImplicitInit(original: original, replacement: replacement), on: base, context: context)
    return ExprSyntax(newMemberAccess)
  }

  // MARK: - Type matching

  /// Returns `true` if the base expression matches the given type name.
  private static func baseMatchesType(_ base: ExprSyntax, typeName: String) -> Bool {
    // Simple type: `Foo`
    if let declRef = base.as(DeclReferenceExprSyntax.self) {
      return declRef.baseName.text == typeName
    }
    // Generic: `Array<Int>` etc.
    if let generic = base.as(GenericSpecializationExprSyntax.self) {
      return generic.trimmedDescription == typeName
    }
    return false
  }

  // MARK: - Description helpers

  /// Builds the replacement description for a constructor rewrite: `.init(args)`
  private static func dotInitDescription(_ call: FunctionCallExprSyntax) -> String {
    var newCall = call
    let dotInit = MemberAccessExprSyntax(
      period: .periodToken(),
      declName: DeclReferenceExprSyntax(baseName: .keyword(.`init`))
    )
    newCall.calledExpression = ExprSyntax(dotInit)
    return newCall.trimmedDescription
  }

  /// Builds the replacement description for a factory call rewrite.
  private static func rewrittenCallDescription(
    _ call: FunctionCallExprSyntax, newCalledExpression: ExprSyntax
  ) -> String {
    var newCall = call
    newCall.calledExpression = newCalledExpression
    return newCall.trimmedDescription
  }
}

extension Finding.Message {
  fileprivate static func useImplicitInit(original: String, replacement: String) -> Finding.Message {
    "replace '\(original)' with '\(replacement)'"
  }
}
