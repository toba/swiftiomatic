import SwiftSyntax

struct Swift62ModernizationRule {
    static let id = "swift62_modernization"
    static let name = "Swift 6.2 Modernization"
    static let summary =
        "Code that can benefit from Swift 6.2 features like @concurrent, Observations, weak let, and Span"
    static let scope: Scope = .suggest
    static let isOptIn = true
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("func work() async { }"),
            Example("""
            class Foo {
                weak var delegate: AnyObject? {
                    didSet { print("changed") }
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    weak var ref: AnyObject? = self
                    ref = nil
                }
            }
            """),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("↓Task.detached { await work() }"),
            Example("↓withObservationTracking { }"),
            Example("""
            class Foo {
                ↓weak var delegate: AnyObject?
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    ↓weak var ref: AnyObject? = self
                    print(ref as Any)
                }
            }
            """),
        ]
    }

    var options = SeverityOption<Self>(.warning)
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
                        severity: configuration.severity,
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
                        severity: configuration.severity,
                        confidence: .medium,
                        suggestion: "for await value in Observations { ... }",
                    ),
                )
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            let hasWeak = node.modifiers.contains { $0.name.text == "weak" }
            let hasAccessors = node.bindings.contains { binding in
                binding.accessorBlock != nil
            }
            if hasWeak, node.bindingSpecifier.tokenKind == .keyword(.var), !hasAccessors {
                let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"

                if isReassigned(bindingName, from: node) {
                    // Variable is genuinely reassigned — needs var
                } else {
                    let varToken = node.bindingSpecifier
                    let correction = SyntaxViolation.Correction(
                        start: varToken.positionAfterSkippingLeadingTrivia,
                        end: varToken.endPositionBeforeTrailingTrivia,
                        replacement: "let",
                    )
                    violations.append(
                        SyntaxViolation(
                            position: node.positionAfterSkippingLeadingTrivia,
                            reason:
                            "weak var '\(bindingName)' is never reassigned — use weak let (SE-0481)",
                            severity: configuration.severity,
                            correction: correction,
                            confidence: .medium,
                            suggestion: "weak let \(bindingName)",
                        ),
                    )
                }
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
                            severity: configuration.severity,
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
                        severity: configuration.severity,
                        confidence: .low,
                        suggestion: "Use @preconcurrency conformance or isolated protocol adoption",
                    ),
                )
            }

            // Detect context parameter threading → @TaskLocal
            let contextParamNames: Set<String> = [
                "context",
                "config",
                "configuration",
                "environment",
            ]
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
                            severity: configuration.severity,
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
                        severity: configuration.severity,
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
                                severity: configuration.severity,
                                confidence: .low,
                                suggestion: "InlineArray<\(elements.count), \(types[0])>",
                            ),
                        )
                    }
                }
            }
        }

        private func isReassigned(_ name: String, from node: VariableDeclSyntax) -> Bool {
            let scope = containingScope(of: Syntax(node))
            let declRange = node.position ..< node.endPosition
            return searchForAssignment(named: name, in: scope, excluding: declRange)
        }

        private func searchForAssignment(
            named name: String, in node: Syntax,
            excluding declRange: Range<AbsolutePosition>,
        ) -> Bool {
            // Skip the declaration itself entirely
            if declRange.contains(node.position), node.endPosition <= declRange.upperBound {
                return false
            }

            // Check SequenceExprSyntax (how SwiftSyntax parses assignments in this version)
            if let seqExpr = node.as(SequenceExprSyntax.self) {
                let elements = Array(seqExpr.elements)
                if elements.count >= 2,
                   let lhs = elements.first?.as(DeclReferenceExprSyntax.self),
                   lhs.baseName.text == name,
                   elements.dropFirst().first?.is(AssignmentExprSyntax.self) == true
                {
                    return true
                }
            }

            // Check InfixOperatorExprSyntax (for compound assignments)
            if let infixExpr = node.as(InfixOperatorExprSyntax.self),
               let lhs = infixExpr.leftOperand.as(DeclReferenceExprSyntax.self),
               lhs.baseName.text == name
            {
                if infixExpr.operator.is(AssignmentExprSyntax.self) { return true }
                
                if let binOp = infixExpr.operator.as(BinaryOperatorExprSyntax.self) {
                    let text = binOp.operator.text
                    if text == "+=" || text == "-=" || text == "*=" || text == "/="
                        || text == "%=" || text == "&=" || text == "|=" || text == "^="
                        || text == "<<=" || text == ">>="
                    {
                        return true
                    }
                }
            }

            // Recurse into children
            for child in node.children(viewMode: .sourceAccurate) {
                if searchForAssignment(named: name, in: child, excluding: declRange) {
                    return true
                }
            }
            return false
        }

        private func containingScope(of node: Syntax) -> Syntax {
            var current = node.parent
            while let parent = current {
                if parent.is(CodeBlockSyntax.self)
                    || parent.is(MemberBlockSyntax.self)
                    || parent.is(SourceFileSyntax.self)
                {
                    return parent
                }
                current = parent.parent
            }
            return node.root
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
                    severity: configuration.severity,
                    confidence: .low,
                ),
            )
        }
    }
}
