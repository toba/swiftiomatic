import SwiftSyntax

struct TypedThrowsRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "typed_throws",
    name: "Typed Throws",
    description: "Functions that throw a single error type should use typed throws",
    kind: .suggest,
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
  func makeVisitor(file: SwiftSource) -> ViolationsSyntaxVisitor<ConfigurationType> {
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
  fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      guard let throwsClause = node.signature.effectSpecifiers?.throwsClause,
        throwsClause.type == nil,
        let body = node.body
      else { return }

      let collector = ThrowCollector(viewMode: .sourceAccurate)
      collector.walk(body)

      guard !collector.thrownTypes.isEmpty,
        !collector.thrownTypes.contains("__unknown__"),
        collector.thrownTypes.count == 1,
        let errorType = collector.thrownTypes.first
      else { return }

      let funcName = node.name.text
      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason: "Function '\(funcName)' throws only '\(errorType)' but declares untyped 'throws'",
          severity: .warning,
          confidence: collector.hasRethrows ? .medium : .high,
          suggestion: "func \(funcName)(...) throws(\(errorType))",
        ),
      )
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      guard let throwsClause = node.signature.effectSpecifiers?.throwsClause,
        throwsClause.type == nil,
        let body = node.body
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
          position: node.positionAfterSkippingLeadingTrivia,
          reason: "Initializer throws only '\(errorType)' but declares untyped 'throws'",
          severity: .warning,
          confidence: collector.hasRethrows ? .medium : .high,
          suggestion: "init(...) throws(\(errorType))",
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
      guard let throwsClause = node.signature.effectSpecifiers?.throwsClause,
        throwsClause.type == nil,
        let body = node.body
      else { return .visitChildren }

      let collector = ThrowCollector(viewMode: .sourceAccurate)
      collector.walk(body)

      guard !collector.thrownTypes.isEmpty,
        collector.thrownTypes.contains("__unknown__"),
        !collector.unknownOffsets.isEmpty
      else { return .visitChildren }

      let knownTypes = collector.thrownTypes.subtracting(["__unknown__"])
      let funcName = node.name.text

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
            label: "Function '\(funcName)'",
            suggestionPrefix: "func \(funcName)(...) ",
          ),
        )
      }

      return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
      guard let throwsClause = node.signature.effectSpecifiers?.throwsClause,
        throwsClause.type == nil,
        let body = node.body
      else { return .visitChildren }

      let collector = ThrowCollector(viewMode: .sourceAccurate)
      collector.walk(body)

      guard !collector.thrownTypes.isEmpty,
        collector.thrownTypes.contains("__unknown__"),
        !collector.unknownOffsets.isEmpty
      else { return .visitChildren }

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
            label: "Initializer",
            suggestionPrefix: "init(...) ",
          ),
        )
      }

      return .visitChildren
    }
  }
}
