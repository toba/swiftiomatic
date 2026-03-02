import Foundation
import SwiftSyntax

struct NamingHeuristicsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NamingHeuristicsConfiguration()
}

extension NamingHeuristicsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NamingHeuristicsRule {}

extension NamingHeuristicsRule {
  static func boolNamingReason(_ name: String) -> String {
    "Bool property '\(name)' doesn't read as an assertion"
  }

  static func boolNamingSuggestion(_ name: String) -> String {
    "Consider a name like 'is\(name.capitalized)' or 'has\(name.capitalized)'"
  }
}

extension NamingHeuristicsRule: AsyncEnrichableRule {
  func enrich(
    file: SwiftSource,
    typeResolver: any TypeResolver,
  ) async -> [RuleViolation] {
    guard let filePath = file.path else { return [] }

    // Find variables without explicit Bool annotation that might be inferred Bool
    let collector = InferredBoolCollector(viewMode: .sourceAccurate)
    collector.walk(file.syntaxTree)

    guard !collector.candidates.isEmpty else { return [] }

    let exprTypes = await typeResolver.expressionTypes(inFile: filePath)
    guard !exprTypes.isEmpty else { return [] }

    var violations: [RuleViolation] = []

    for candidate in collector.candidates {
      let isBool = exprTypes.contains { info in
        info.offset == candidate.offset
          && (info.typeName == "Bool" || info.typeName == "Swift.Bool")
      }
      if isBool, !NamingConventionChecker.isAssertionNamed(candidate.name),
        !candidate.name.hasPrefix("_")
      {
        violations.append(
          RuleViolation(
            ruleDescription: Self.description,
            severity: options.severity,
            location: Location(
              file: filePath, line: candidate.line, column: candidate.column,
            ),
            reason: Self.boolNamingReason(candidate.name),
            confidence: .low,
            suggestion: Self.boolNamingSuggestion(candidate.name),
          ),
        )
      }
    }

    return violations
  }
}

extension NamingHeuristicsRule {
  fileprivate struct InferredBoolCandidate {
    let name: String
    let offset: Int
    let line: Int
    let column: Int
  }

  fileprivate final class InferredBoolCollector: SyntaxVisitor {
    var candidates: [InferredBoolCandidate] = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
      for binding in node.bindings {
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
          continue
        }
        // Only interested in bindings without explicit type annotation but with an initializer
        guard binding.typeAnnotation == nil,
          let initializer = binding.initializer
        else { continue }

        let initExpr = initializer.value
        let loc = binding.startLocation(
          converter: .init(fileName: "", tree: node.root),
        )
        candidates.append(
          InferredBoolCandidate(
            name: pattern.identifier.text,
            offset: initExpr.positionAfterSkippingLeadingTrivia.utf8Offset,
            line: loc.line,
            column: loc.column,
          ),
        )
      }
      return .visitChildren
    }
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ProtocolDeclSyntax) {
      let name = node.name.text
      guard name.hasSuffix("able") || name.hasSuffix("ible") else { return }

      let methods = node.memberBlock.members
        .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
      let hasActionVerbs = methods.contains { method in
        let n = method.name.text
        return NamingConventionChecker.actionVerbPrefixes.contains { n.hasPrefix($0) }
      }

      if hasActionVerbs {
        violations.append(
          SyntaxViolation(
            position: node.name.positionAfterSkippingLeadingTrivia,
            reason:
              "Protocol '\(name)' uses -able suffix but conformers perform the action — consider -ing suffix",
            severity: .warning,
            confidence: .low,
            suggestion: name.replacingSuffix("able", with: "ing")
              ?? name.replacingSuffix("ible", with: "ing"),
          ),
        )
      }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      for binding in node.bindings {
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else { continue }
        let name = pattern.identifier.text

        if let typeAnnotation = binding.typeAnnotation,
          typeAnnotation.type.trimmedDescription == "Bool"
        {
          checkBoolNaming(
            name: name,
            position: pattern.positionAfterSkippingLeadingTrivia,
          )
        }
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      let name = node.name.text

      // Existing: factory method prefix check (static only)
      if node.modifiers.contains(where: { $0.name.text == "static" }),
        let suggestion = NamingConventionChecker.factoryMethodSuggestion(for: name)
      {
        violations.append(
          SyntaxViolation(
            position: node.name.positionAfterSkippingLeadingTrivia,
            reason:
              "Factory method '\(name)' should use 'make' prefix per Swift API Design Guidelines",
            severity: .warning,
            confidence: .medium,
            suggestion: suggestion,
          ),
        )
      }

      // Mutating/non-mutating reversed conventions (ed/ing)
      let isMutating = node.modifiers.contains { $0.name.text == "mutating" }
      if isMutating {
        // Mutating methods should use base verb form (sort, append, reverse)
        // but NOT past-tense (sorted) or gerund (sorting)
        if name.hasSuffix("ed") || name.hasSuffix("ing") {
          let baseName =
            name.hasSuffix("ed")
            ? String(name.dropLast(2))
            : String(name.dropLast(3))
          violations.append(
            SyntaxViolation(
              position: node.name.positionAfterSkippingLeadingTrivia,
              reason:
                "Mutating method '\(name)' uses -ed/-ing suffix — mutating methods should use imperative form",
              severity: .warning,
              confidence: .medium,
              suggestion: "Rename to '\(baseName)' (imperative verb form)",
            ),
          )
        }
      } else if !node.modifiers.contains(where: { $0.name.text == "static" }) {
        // Non-mutating instance methods that return a modified copy should use -ed/-ing
        let returnsValue = node.signature.returnClause != nil
        let knownMutatingVerbs: Set<String> = [
          "sort", "reverse", "shuffle", "append", "remove", "insert",
          "filter", "partition",
        ]
        if returnsValue, knownMutatingVerbs.contains(name) {
          let edForm = name + "ed"
          violations.append(
            SyntaxViolation(
              position: node.name.positionAfterSkippingLeadingTrivia,
              reason:
                "Non-mutating method '\(name)' that returns a value should use -ed/-ing suffix",
              severity: .warning,
              confidence: .low,
              suggestion: "Rename to '\(edForm)' for the non-mutating variant",
            ),
          )
        }
      }

      // First-argument label conventions
      let params = node.signature.parameterClause.parameters
      guard let firstParam = params.first, params.count >= 1 else { return }
      let firstName = firstParam.firstName.text
      let secondName = firstParam.secondName?.text

      // If function name forms a grammatical phrase with the first arg, label should be omitted
      // e.g., func contains(_ element: Element) not func contains(element: Element)
      let phrasalVerbs: Set<String> = [
        "contains", "append", "insert", "remove", "add", "subtract",
        "multiply", "divide",
      ]
      if phrasalVerbs.contains(name), firstName != "_", secondName != "_" {
        violations.append(
          SyntaxViolation(
            position: firstParam.positionAfterSkippingLeadingTrivia,
            reason:
              "First argument of '\(name)' forms a grammatical phrase — label should be omitted (_)",
            severity: .warning,
            confidence: .low,
            suggestion: "Use _ as the external label: \(name)(_ \(secondName ?? firstName):)",
          ),
        )
      }
    }

    private func checkBoolNaming(name: String, position: AbsolutePosition) {
      if !NamingConventionChecker.isAssertionNamed(name), !name.hasPrefix("_") {
        violations.append(
          SyntaxViolation(
            position: position,
            reason: NamingHeuristicsRule.boolNamingReason(name),
            severity: .warning,
            confidence: .low,
            suggestion: NamingHeuristicsRule.boolNamingSuggestion(name),
          ),
        )
      }
    }
  }
}
