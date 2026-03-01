import Foundation
import SwiftSyntax

struct TypedThrowsRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "typed_throws",
    name: "Typed Throws",
    description: "Functions that throw a single error type should use typed throws",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("func parse() throws(ParseError) { throw ParseError.invalid }"),
      Example("func work() throws { throw ErrorA.a; throw ErrorB.b }"),
      Example("func safe() { }"),
    ],
    triggeringExamples: [
      Example("↓func parse() throws { throw ParseError.invalid }")
    ],
  )
}

extension TypedThrowsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension TypedThrowsRule: OptInRule {}

extension TypedThrowsRule: AsyncEnrichableRule {
  func enrich(
    file: SwiftSource,
    typeResolver: any TypeResolver,
  ) async -> [RuleViolation] {
    guard let filePath = file.path else { return [] }

    let visitor = UnknownThrowCollectorVisitor(viewMode: .sourceAccurate)
    visitor.walk(file.syntaxTree)

    var violations: [RuleViolation] = []

    for query in visitor.queries {
      guard
        let resolved = await typeResolver.resolveType(
          inFile: filePath, offset: query.offset,
        )
      else { continue }

      var allTypes = query.knownTypes
      allTypes.insert(resolved.typeName)

      if allTypes.count == 1, let errorType = allTypes.first {
        violations.append(
          RuleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: filePath, line: query.line, character: query.column),
            reason:
              "\(query.label) throws only '\(errorType)' but declares untyped 'throws'",
            confidence: query.hasRethrows ? .medium : .high,
            suggestion: "\(query.suggestionPrefix)throws(\(errorType))",
          ),
        )
      }
    }

    return violations
  }
}

extension TypedThrowsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      checkResultReturnType(node)

      let funcName = node.name.text
      checkThrowsClause(
        throwsClause: node.signature.effectSpecifiers?.throwsClause,
        body: node.body,
        label: "Function '\(funcName)'",
        suggestionPrefix: "func \(funcName)(...) ",
        position: node.positionAfterSkippingLeadingTrivia,
      )
    }

    // Check for Result<T, E> return type on non-throwing functions
    private func checkResultReturnType(_ node: FunctionDeclSyntax) {
      // Only interested in non-throwing functions
      guard node.signature.effectSpecifiers?.throwsClause == nil else { return }

      let returnTypeStr = node.signature.returnClause?.type.trimmedDescription ?? ""
      guard returnTypeStr.hasPrefix("Result<"),
        returnTypeStr.hasSuffix(">")
      else { return }

      // Extract the error type from Result<Success, Failure>
      let inner = String(returnTypeStr.dropFirst("Result<".count).dropLast(1))
      let genericArgs = inner.split(separator: ",", maxSplits: 1).map {
        $0.trimmingCharacters(in: .whitespaces)
      }
      guard genericArgs.count == 2 else { return }
      let successType = genericArgs[0]
      let errorType = genericArgs[1]
      guard errorType != "Error" && errorType != "any Error" else { return }

      let funcName = node.name.text
      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason:
            "Function '\(funcName)' returns Result<\(successType), \(errorType)> — consider throws(\(errorType)) -> \(successType) instead",
          severity: .warning,
          confidence: .low,
          suggestion: "func \(funcName)(...) throws(\(errorType)) -> \(successType)",
        ),
      )
    }

    override func visitPost(_ node: CatchClauseSyntax) {
      // Detect `catch let error as SpecificType` — suggests the enclosing function should use typed throws
      let catchItems = node.catchItems
      guard catchItems.count == 1,
        let item = catchItems.first,
        let pattern = item.pattern
      else { return }

      // `catch let error as Type` parses as ValueBindingPattern > ExpressionPattern > AsExpr
      // Use trimmedDescription as a pragmatic fallback for all AST shapes
      let patternStr = pattern.trimmedDescription
      guard patternStr.contains(" as ") else { return }

      // Extract the type name after the last " as "
      guard let asRange = patternStr.range(of: " as ", options: .backwards) else { return }
      let errorType = String(patternStr[asRange.upperBound...])

      // Walk up to find enclosing function
      var current: Syntax? = Syntax(node)
      while let parent = current?.parent {
        if let funcDecl = parent.as(FunctionDeclSyntax.self) {
          if let throwsClause = funcDecl.signature.effectSpecifiers?.throwsClause,
            throwsClause.type == nil
          {
            violations.append(
              SyntaxViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason:
                  "Catch clause downcasts to '\(errorType)' — function '\(funcDecl.name.text)' may benefit from typed throws",
                severity: .warning,
                confidence: .medium,
                suggestion: "func \(funcDecl.name.text)(...) throws(\(errorType))",
              ),
            )
          }
          break
        }
        if parent.as(ClosureExprSyntax.self) != nil {
          break  // Don't cross closure boundaries
        }
        current = parent
      }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      checkThrowsClause(
        throwsClause: node.signature.effectSpecifiers?.throwsClause,
        body: node.body,
        label: "Initializer",
        suggestionPrefix: "init(...) ",
        position: node.positionAfterSkippingLeadingTrivia,
      )
    }

    private func checkThrowsClause(
      throwsClause: ThrowsClauseSyntax?,
      body: CodeBlockSyntax?,
      label: String,
      suggestionPrefix: String,
      position: AbsolutePosition,
    ) {
      guard let throwsClause, throwsClause.type == nil,
        let body
      else { return }

      let collector = ThrowCollector(viewMode: .sourceAccurate)
      collector.walk(body)

      guard !collector.thrownTypes.isEmpty,
        !collector.thrownTypes.contains("__unknown__"),
        collector.thrownTypes.count == 1,
        let errorType = collector.thrownTypes.first
      else { return }

      violations.append(
        SyntaxViolation(
          position: position,
          reason: "\(label) throws only '\(errorType)' but declares untyped 'throws'",
          severity: .warning,
          confidence: collector.hasRethrows ? .medium : .high,
          suggestion: "\(suggestionPrefix)throws(\(errorType))",
        ),
      )
    }
  }

  /// Collects functions with `__unknown__` throw types for async resolution.
  fileprivate struct UnknownThrowQuery {
    let offset: Int
    let line: Int
    let column: Int
    let knownTypes: Set<String>
    let hasRethrows: Bool
    let label: String
    let suggestionPrefix: String
  }

  fileprivate final class UnknownThrowCollectorVisitor: SyntaxVisitor {
    var queries: [UnknownThrowQuery] = []

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
      let funcName = node.name.text
      collectUnknownThrowQueries(
        throwsClause: node.signature.effectSpecifiers?.throwsClause,
        body: node.body,
        node: Syntax(node),
        label: "Function '\(funcName)'",
        suggestionPrefix: "func \(funcName)(...) ",
      )
      return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
      collectUnknownThrowQueries(
        throwsClause: node.signature.effectSpecifiers?.throwsClause,
        body: node.body,
        node: Syntax(node),
        label: "Initializer",
        suggestionPrefix: "init(...) ",
      )
      return .visitChildren
    }

    private func collectUnknownThrowQueries(
      throwsClause: ThrowsClauseSyntax?,
      body: CodeBlockSyntax?,
      node: Syntax,
      label: String,
      suggestionPrefix: String,
    ) {
      guard let throwsClause, throwsClause.type == nil,
        let body
      else { return }

      let collector = ThrowCollector(viewMode: .sourceAccurate)
      collector.walk(body)

      guard !collector.thrownTypes.isEmpty,
        collector.thrownTypes.contains("__unknown__"),
        !collector.unknownOffsets.isEmpty
      else { return }

      let knownTypes = collector.thrownTypes.subtracting(["__unknown__"])

      for offset in collector.unknownOffsets {
        let loc = node.startLocation(
          converter: .init(fileName: "", tree: node.root),
        )
        queries.append(
          UnknownThrowQuery(
            offset: offset,
            line: loc.line,
            column: loc.column,
            knownTypes: knownTypes,
            hasRethrows: collector.hasRethrows,
            label: label,
            suggestionPrefix: suggestionPrefix,
          ),
        )
      }
    }
  }
}
