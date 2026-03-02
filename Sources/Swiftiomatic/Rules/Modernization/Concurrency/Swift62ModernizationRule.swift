import SwiftSyntax

struct Swift62ModernizationRule {
    static let id = "swift62_modernization"
    static let name = "Swift 6.2 Modernization"
    static let summary = "Code that can benefit from Swift 6.2 features like @concurrent, Observations, weak let, and Span"
    static let scope: Scope = .suggest
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("func work() async { }")
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("↓Task.detached { await work() }"),
              Example("↓withObservationTracking { }"),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension Swift62ModernizationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension Swift62ModernizationRule: Rule {}

extension Swift62ModernizationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription

      if callee == "Task.detached" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Task.detached may be replaceable with @concurrent",
            severity: .warning,
            confidence: .low,
            suggestion:
              "Use @concurrent on an async function instead — but note @concurrent inherits @TaskLocal values while Task.detached drops them",
          ),
        )
      }

      if callee == "withObservationTracking" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "withObservationTracking can be replaced with Observations AsyncSequence in Swift 6.2",
            severity: .warning,
            confidence: .medium,
            suggestion: "for await value in Observations { ... }",
          ),
        )
      }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      let hasWeak = node.modifiers.contains { $0.name.text == "weak" }
      if hasWeak, node.bindingSpecifier.tokenKind == .keyword(.var) {
        let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "weak var '\(bindingName)' — if never reassigned after init, use weak let (SE-0481)",
            severity: .warning,
            confidence: .low,
          ),
        )
      }

      // Detect mutable static var without isolation on non-actor types
      let hasStatic = node.modifiers.contains { $0.name.text == "static" }
      let isVar = node.bindingSpecifier.tokenKind == .keyword(.var)
      if hasStatic, isVar {
        let hasIsolation = node.attributes.contains {
          $0.trimmedDescription.contains("@MainActor")
        }
        let isPrivate = node.modifiers.contains {
          $0.name.text == "private" || $0.name.text == "fileprivate"
        }
        // Only flag non-private static vars without isolation
        if !hasIsolation, !isPrivate, !isInsideActor(Syntax(node)) {
          let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                "Mutable static var '\(bindingName)' without isolation — data race risk in concurrent contexts",
              severity: .warning,
              confidence: .low,
              suggestion: "Protect with actor isolation, Mutex, or convert to @TaskLocal",
            ),
          )
        }
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      // Detect nonisolated on protocol-required methods inside @MainActor type
      let hasNonisolated = node.modifiers.contains { $0.name.text == "nonisolated" }
      if hasNonisolated, isInsideMainActorType(Syntax(node)) {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "nonisolated method '\(node.name.text)' in @MainActor type — consider isolated conformances (SE-0470)",
            severity: .warning,
            confidence: .low,
            suggestion: "Use @preconcurrency conformance or isolated protocol adoption",
          ),
        )
      }

      // Detect context parameter threading → @TaskLocal
      let contextParamNames: Set<String> = ["context", "config", "configuration", "environment"]
      let hasContextParam = node.signature.parameterClause.parameters.contains { param in
        contextParamNames.contains(param.firstName.text)
          || contextParamNames.contains(param.secondName?.text ?? "")
      }
      if hasContextParam, let body = node.body {
        // Check if the context parameter is passed through to every sub-call
        let calls = body.statements.compactMap { stmt -> FunctionCallExprSyntax? in
          if let call = stmt.item.as(FunctionCallExprSyntax.self) { return call }
          if let ret = stmt.item.as(ReturnStmtSyntax.self),
            let call = ret.expression?.as(FunctionCallExprSyntax.self)
          {
            return call
          }
          return nil
        }
        let passesContext = calls.filter { call in
          call.arguments.contains { arg in
            contextParamNames.contains(arg.expression.trimmedDescription)
          }
        }
        if calls.count >= 2, passesContext.count == calls.count {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                "Function '\(node.name.text)' threads context parameter to all callees — consider @TaskLocal",
              severity: .warning,
              confidence: .low,
              suggestion: "Use @TaskLocal for implicit context propagation",
            ),
          )
        }
      }
    }

    override func visitPost(_ node: TypeAnnotationSyntax) {
      let typeStr = node.type.trimmedDescription
      if typeStr.contains("UnsafeRawBufferPointer")
        || typeStr.contains("UnsafeBufferPointer")
        || typeStr.contains("UnsafeMutableRawBufferPointer")
        || typeStr.contains("UnsafeMutableBufferPointer")
      {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Unsafe buffer pointer — consider Span/RawSpan (macOS 26.0+)",
            severity: .warning,
            confidence: .low,
            suggestion: "Use Span<T> or RawSpan for safe, non-owning buffer access",
          ),
        )
      }

      // Detect tuple as fixed-size buffer → InlineArray
      if let tupleType = node.type.as(TupleTypeSyntax.self) {
        let elements = tupleType.elements
        if elements.count >= 3 {
          let types = elements.map(\.type.trimmedDescription)
          let allSame = types.allSatisfy { $0 == types[0] }
          if allSame {
            violations.append(
              SyntaxViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason:
                  "Homogeneous tuple of \(elements.count) elements — consider InlineArray<\(elements.count), \(types[0])> (SE-0453)",
                severity: .warning,
                confidence: .low,
                suggestion: "InlineArray<\(elements.count), \(types[0])>",
              ),
            )
          }
        }
      }
    }

    private func isInsideActor(_ node: Syntax) -> Bool {
      node.nearestAncestor(ofType: ActorDeclSyntax.self) != nil
    }

    private func isInsideMainActorType(_ node: Syntax) -> Bool {
      func hasMainActorAttribute(_ attributes: AttributeListSyntax) -> Bool {
        attributes.contains { attr in
          attr.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "MainActor"
        }
      }
      if let classDecl = node.nearestAncestor(ofType: ClassDeclSyntax.self) {
        return hasMainActorAttribute(classDecl.attributes)
      }
      if let structDecl = node.nearestAncestor(ofType: StructDeclSyntax.self) {
        return hasMainActorAttribute(structDecl.attributes)
      }
      return false
    }

    override func visitPost(_ node: AccessorDeclSyntax) {
      let accessorKind = node.accessorSpecifier.text
      guard accessorKind == "didSet" || accessorKind == "willSet",
        let body = node.body, body.statements.count > 1
      else { return }

      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason:
            "\(accessorKind) with side-effect logic — consider Observations framework if on an @Observable type",
          severity: .warning,
          confidence: .low,
        ),
      )
    }
  }
}
