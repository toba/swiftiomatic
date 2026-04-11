import SwiftSyntax

struct AnyEliminationRule {
  static let id = "any_elimination"
  static let name = "Any Elimination"
  static let summary =
    "Usage of Any/AnyObject erases type safety and should be replaced with specific types or generics"
  static let scope: Scope = .suggest
  static let isOptIn = true
  static let canEnrichAsync = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("var name: String = \"\""),
      Example("func process(_ item: Codable) {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("var value: ↓Any = 0"),
      Example("func process(_ dict: ↓[String: Any]) {}"),
      Example("var items: ↓AnyHashable = 0"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension AnyEliminationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AnyEliminationRule: AsyncEnrichableRule {
  func enrich(
    file: SwiftSource,
    typeResolver: any TypeResolver,
  ) async -> [RuleViolation] {
    guard let filePath = file.path else { return [] }

    // Find type annotations that aren't literally Any but might alias to it
    let collector = TypeAliasCollector(viewMode: .sourceAccurate)
    collector.walk(file.syntaxTree)

    var violations: [RuleViolation] = []

    for query in collector.queries {
      guard
        let resolved = await typeResolver.resolveType(
          inFile: filePath, offset: query.offset,
        )
      else { continue }

      if resolved.typeName == "Any" || resolved.typeName == "Swift.Any" {
        violations.append(
          RuleViolation(
            ruleType: Self.self,
            severity: options.severity,
            location: Location(file: filePath, line: query.line, column: query.column),
            reason: "Type '\(query.typeStr)' resolves to 'Any' — type safety is erased",
            confidence: .high,
            suggestion:
              "Use a specific type, protocol, or generic parameter instead of the alias",
          ),
        )
      }
    }

    return violations
  }
}

extension AnyEliminationRule {
  fileprivate struct TypeAliasQuery {
    let offset: Int
    let line: Int
    let column: Int
    let typeStr: String
  }

  fileprivate final class TypeAliasCollector: SyntaxVisitor {
    var queries: [TypeAliasQuery] = []

    override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
      collectIfNotLiteralAny(node.type, at: node)
      return .visitChildren
    }

    override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
      collectIfNotLiteralAny(node.type, at: node)
      return .visitChildren
    }

    private func collectIfNotLiteralAny(_ type: TypeSyntax, at node: some SyntaxProtocol) {
      let typeStr = type.trimmedDescription
      guard AnyTypeClassifier.classifyAnyType(typeStr) == nil else { return }
      let loc = node.startLocation(
        converter: .init(fileName: "", tree: node.root),
      )
      queries.append(
        TypeAliasQuery(
          offset: type.positionAfterSkippingLeadingTrivia.utf8Offset,
          line: loc.line,
          column: loc.column,
          typeStr: typeStr,
        ),
      )
    }
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TypeAnnotationSyntax) {
      checkForAny(in: node.type)
    }

    override func visitPost(_ node: ReturnClauseSyntax) {
      checkForAny(in: node.type)
    }

    override func visitPost(_ node: DictionaryTypeSyntax) {
      let key = node.key.trimmedDescription
      let value = node.value.trimmedDescription
      if key == "String", value == "Any" || value == "any Sendable" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "[String: \(value)] dictionary should be a Codable struct",
            severity: configuration.severity,
            confidence: .medium,
            suggestion: "Define a struct with typed properties instead",
          ),
        )
      }
    }

    override func visitPost(_ node: AsExprSyntax) {
      if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Force cast 'as!' — trace back to where the type was erased",
            severity: configuration.severity,
            confidence: .medium,
            suggestion: "Use generics or a typed API to avoid the cast",
          ),
        )
      }
    }

    private func checkForAny(in type: TypeSyntax) {
      guard let match = AnyTypeClassifier.classifyAnyType(type.trimmedDescription)
      else { return }
      violations.append(
        SyntaxViolation(
          position: type.positionAfterSkippingLeadingTrivia,
          reason: match.message,
          severity: configuration.severity,
          confidence: match == .any ? .medium : .low,
          suggestion: match.suggestion,
        ),
      )
    }
  }
}
