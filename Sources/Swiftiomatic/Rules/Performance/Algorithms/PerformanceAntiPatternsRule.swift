import SwiftSyntax

struct PerformanceAntiPatternsRule {
    static let id = "performance_anti_patterns"
    static let name = "Performance Anti-Patterns"
    static let summary = "Detects common performance anti-patterns like Date() for benchmarking and mutation during iteration"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("let now = ContinuousClock.now"),
              Example("array.removeAll(where: { $0.isEmpty })"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                for item in ↓items {
                    items.remove(at: 0)
                }
                """,
              )
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension PerformanceAntiPatternsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PerformanceAntiPatternsRule {}

extension PerformanceAntiPatternsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var withLockDepth = 0

    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription
      if callee == "Date" || callee == "Date.init" {
        if let parent = node.parent,
          parent.trimmedDescription.contains("timeIntervalSince")
            || parent.trimmedDescription.contains("elapsed")
            || parent.trimmedDescription.contains("start")
            || parent.trimmedDescription.contains("duration")
        {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason: "Date() used for timing — can go backwards due to NTP adjustments",
              severity: .warning,
              confidence: .medium,
              suggestion: "Use ContinuousClock.now for monotonic timing",
            ),
          )
        }
      }

      // Detect withLock containing await
      if callee.hasSuffix(".withLock") || callee == "withLock" {
        withLockDepth += 1
        defer { withLockDepth -= 1 }

        if withLockDepth > 1 {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason: "Nested withLock — potential deadlock risk",
              severity: .error,
              confidence: .high,
            ),
          )
        }

        if let trailingClosure = node.trailingClosure {
          let bodyStr = trailingClosure.statements.trimmedDescription
          if bodyStr.contains("await ") {
            violations.append(
              SyntaxViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason:
                  "withLock closure contains await — lock will be held across suspension point",
                severity: .error,
                confidence: .high,
                suggestion: "Move the await outside the lock or use an actor instead",
              ),
            )
          }
        }
      }
    }

    override func visitPost(_ node: ForStmtSyntax) {
      if let sequenceExpr = node.sequence.as(DeclReferenceExprSyntax.self) {
        let collectionName = sequenceExpr.baseName.text

        let mutationFinder = MutationDuringIterationFinder(
          collectionName: collectionName,
          viewMode: .sourceAccurate,
        )
        mutationFinder.walk(node.body)

        if mutationFinder.foundMutation {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                "Collection '\(collectionName)' is mutated during iteration — may crash or skip elements",
              severity: .error,
              confidence: .high,
              suggestion: "Use removeAll(where:), filter, or collect indices first",
            ),
          )
        }

        // Detect Data.dropFirst() in loop body
        let bodyStr = node.body.statements.trimmedDescription
        if bodyStr.contains("\(collectionName).dropFirst()") {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                "Calling .dropFirst() on '\(collectionName)' inside loop — O(n²) if Data or contiguous collection",
              severity: .warning,
              confidence: .high,
              suggestion: "Use an index-based approach or Slice",
            ),
          )
        }
      }

      // Detect for-await over Observations with expensive body
      if let awaitKeyword = node.awaitKeyword {
        let sequenceStr = node.sequence.trimmedDescription
        if sequenceStr.contains("Observations") {
          let stmtCount = node.body.statements.count
          let bodyStr = node.body.statements.trimmedDescription
          if stmtCount > 2 || bodyStr.contains("await ") {
            violations.append(
              SyntaxViolation(
                position: awaitKeyword.positionAfterSkippingLeadingTrivia,
                reason:
                  "for-await over Observations with expensive body — consider debouncing or extracting work",
                severity: .warning,
                confidence: .low,
              ),
            )
          }
        }
      }
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
      let memberName = node.declName.baseName.text

      // Detect chained .flatMap/.compactMap/.map without .lazy
      let chainableOps: Set<String> = ["map", "flatMap", "compactMap", "filter"]
      if chainableOps.contains(memberName) {
        // Walk up the chain to count consecutive functional operations
        var chainLength = 1
        var current: ExprSyntax? = node.base
        while let memberAccess = current?.as(FunctionCallExprSyntax.self),
          let callee = memberAccess.calledExpression.as(MemberAccessExprSyntax.self),
          chainableOps.contains(callee.declName.baseName.text)
        {
          chainLength += 1
          current = callee.base
        }

        if chainLength >= 3 {
          // Check the root of the chain doesn't already use .lazy
          var root: ExprSyntax? = node.base
          for _ in 0..<(chainLength - 1) {
            if let call = root?.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self)
            {
              root = member.base
            }
          }
          let rootStr = root?.trimmedDescription ?? ""
          if !rootStr.hasSuffix(".lazy") {
            violations.append(
              SyntaxViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason:
                  "Chain of \(chainLength)+ functional transforms without .lazy — creates intermediate arrays",
                severity: .warning,
                confidence: .medium,
                suggestion: "Prefix the chain with .lazy to avoid intermediate allocations",
              ),
            )
          }
        }
      }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      // Detect @TaskLocal for business-logic state
      let hasTaskLocal = node.attributes.contains { $0.trimmedDescription == "@TaskLocal" }
      guard hasTaskLocal else { return }

      let bindingName = node.bindings.first?.pattern.trimmedDescription ?? ""
      let diagnosticNames: Set<String> = [
        "requestID", "traceID", "spanID", "correlationID", "logger", "tracer",
        "requestId", "traceId", "spanId", "correlationId",
      ]
      if !diagnosticNames.contains(bindingName),
        !bindingName.lowercased().contains("trace"),
        !bindingName.lowercased().contains("log"),
        !bindingName.lowercased().contains("diagnostic")
      {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "@TaskLocal '\(bindingName)' appears to hold business-logic state rather than diagnostics",
            severity: .warning,
            confidence: .low,
            suggestion:
              "@TaskLocal is best for trace IDs and logging context — use explicit parameters or actors for business state",
          ),
        )
      }
    }

    override func visitPost(_ node: FunctionParameterSyntax) {
      // Detect concrete collection parameters that could be Span
      let typeStr = node.type.trimmedDescription
      let spanCandidates = ["[", "ArraySlice<", "ContiguousArray<"]
      let isArrayType = spanCandidates.contains { typeStr.hasPrefix($0) }
      guard isArrayType else { return }

      // Only flag if the parameter is not inout (Span is read-only)
      let isInout = typeStr.hasPrefix("inout ")
      guard !isInout else { return }

      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason:
            "Collection parameter '\(node.firstName.text)' could potentially accept Span for non-owning access",
          severity: .warning,
          confidence: .low,
          suggestion:
            "Consider Span<Element> for read-only, non-owning buffer access (macOS 26.0+)",
        ),
      )
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      // Detect public generic functions missing @inlinable
      let isPublic = node.modifiers.contains { $0.name.text == "public" }
      guard isPublic else { return }

      let hasGenericParams = node.genericParameterClause != nil
      let hasSomeParams = node.signature.parameterClause.parameters.contains {
        $0.type.trimmedDescription.hasPrefix("some ")
      }
      guard hasGenericParams || hasSomeParams else { return }

      let hasInlinable = node.attributes.contains {
        $0.trimmedDescription.contains("@inlinable")
      }
      guard !hasInlinable else { return }

      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason:
            "Public generic function '\(node.name.text)' without @inlinable — prevents specialization by callers",
          severity: .warning,
          confidence: .low,
          suggestion: "Add @inlinable if this is a library module to enable generic specialization",
        ),
      )
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      // Detect @TaskLocal read inside Task.detached
      let name = node.baseName.text
      guard name.hasPrefix("$") else { return }

      // Walk up to find if we're inside Task.detached
      var current: Syntax? = Syntax(node)
      while let parent = current?.parent {
        if let call = parent.as(FunctionCallExprSyntax.self),
          call.calledExpression.trimmedDescription == "Task.detached"
        {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                "@TaskLocal '\(name)' read inside Task.detached — value will be nil/default since detached tasks don't inherit task-local values",
              severity: .warning,
              confidence: .medium,
            ),
          )
          break
        }
        current = parent
      }
    }

    override func visitPost(_ node: ArrayExprSyntax) {
      let elementCount = node.elements.count
      guard elementCount <= 1, node.parent?.is(LabeledExprSyntax.self) == true else { return }

      let label = elementCount == 0 ? "EmptyCollection()" : "CollectionOfOne(...)"
      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason: elementCount == 0
            ? "Empty array literal may heap-allocate when passed to generic Collection/Sequence parameter"
            : "Single-element array literal may heap-allocate when passed to generic Collection/Sequence parameter",
          severity: .warning,
          confidence: .low,
          suggestion: "Consider \(label) for zero-allocation alternative",
        ),
      )
    }
  }
}
