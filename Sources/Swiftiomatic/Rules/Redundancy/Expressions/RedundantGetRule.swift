import SwiftSyntax

struct RedundantGetRule {
    static let id = "redundant_get"
    static let name = "Redundant Get"
    static let summary = "Computed read-only properties should avoid using the `get` keyword"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                var foo: Int {
                    return 5
                }
                """,
            ),
            Example(
                """
                var foo: Int {
                    get { return 5 }
                    set { _foo = newValue }
                }
                """,
            ),
            Example(
                """
                var enabled: Bool { @objc(isEnabled) get { true } }
                """,
            ),
            Example(
                """
                var foo: Int {
                    get async throws {
                        try await getFoo()
                    }
                }
                """,
            ),
            Example(
                """
                func foo() {
                    get {
                        self.lookup(index)
                    }
                }
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                var foo: Int {
                    ↓get {
                        return 5
                    }
                }
                """,
            ),
            Example("var foo: Int { ↓get { return 5 } }"),
            Example(
                """
                subscript(_ index: Int) {
                    ↓get {
                        return lookup(index)
                    }
                }
                """,
            ),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example(
                """
                var foo: Int {
                    ↓get {
                        return 5
                    }
                }
                """,
            ): Example(
                """
                var foo: Int {
                    return 5
                }
                """,
            ),
            Example("var foo: Int { ↓get { return 5 } }"): Example(
                "var foo: Int { return 5 }",
            ),
            Example(
                """
                subscript(_ index: Int) {
                    ↓get {
                        return lookup(index)
                    }
                }
                """,
            ): Example(
                """
                subscript(_ index: Int) {
                    return lookup(index)
                }
                """,
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension RedundantGetRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension RedundantGetRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: AccessorBlockSyntax) {
            guard node.hasRedundantGet else { return }
            let getter = node.accessorsList.first!
            violations.append(getter.positionAfterSkippingLeadingTrivia)
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
            guard node.hasRedundantGet,
                  let getter = node.accessorsList.first,
                  let body = getter.body
            else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return super.visit(
                node.with(\.accessors, .getter(body.statements)),
            )
        }
    }
}

extension AccessorBlockSyntax {
    fileprivate var hasRedundantGet: Bool {
        let list = accessorsList
        // Must have exactly one accessor and it must be `get`
        guard list.count == 1,
              let getter = list.first,
              getter.accessorSpecifier.tokenKind == .keyword(.get)
        else {
            return false
        }
        // Must not have attributes (e.g. @objc)
        guard getter.attributes.isEmpty else { return false }
        // Must not have effectSpecifiers (async/throws)
        guard getter.effectSpecifiers == nil else { return false }
        // Must be inside a computed property or subscript, not a function
        guard
            parent?.is(PatternBindingSyntax.self) == true
            || parent?.is(SubscriptDeclSyntax.self) == true
        else {
            return false
        }
        return true
    }
}
