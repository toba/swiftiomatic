import SwiftSyntax

struct DelegateToAsyncStreamRule {
    static let id = "delegate_to_async_stream"
    static let name = "Delegate to AsyncStream"
    static let summary =
        "Protocol declarations where all methods are single-callback-shaped may benefit from an AsyncStream wrapper"
    static let scope: Scope = .suggest
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                protocol DataSource {
                    func numberOfItems() -> Int
                    func item(at index: Int) -> Item
                }
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                ↓protocol DownloadDelegate {
                    func downloadDidStart(_ download: Download)
                    func downloadDidFinish(_ download: Download, data: Data)
                    func downloadDidFail(_ download: Download, error: Error)
                }
                """,
                configuration: ["severity": "warning"],
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension DelegateToAsyncStreamRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension DelegateToAsyncStreamRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        /// Common delegate method name patterns (lowercase for case-insensitive matching)
        private static let delegatePatterns = [
            "did", "will", "should",
        ]

        override func visitPost(_ node: ProtocolDeclSyntax) {
            let name = node.name.text

            let methods = node.memberBlock.members
                .compactMap { $0.decl.as(FunctionDeclSyntax.self) }

            // Need at least 2 methods to suggest a stream pattern
            guard methods.count >= 2 else { return }

            // Check if ALL methods look like delegate callbacks
            let delegateMethods = methods.filter { method in
                isDelegateMethod(method)
            }

            // All methods should be delegate-shaped
            guard delegateMethods.count == methods.count else { return }

            // Check for no return types (delegate methods are typically void)
            let allVoid = methods.allSatisfy { $0.signature.returnClause == nil }
            guard allVoid else { return }

            // Check name hints — protocol name contains "Delegate", "Observer", "Listener"
            let isDelegateNamed =
                name.contains("Delegate") || name.contains("Observer")
                    || name.contains("Listener") || name.contains("Handler")

            // If not delegate-named, at least check the method names
            let hasDelegateMethodNames = delegateMethods.contains { method in
                let methodName = method.name.text.lowercased()
                return Self.delegatePatterns.contains { methodName.contains($0) }
            }

            guard isDelegateNamed || hasDelegateMethodNames else { return }

            violations.append(
                SyntaxViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason:
                    "Protocol '\(name)' has \(methods.count) delegate-style callbacks — consider an AsyncStream wrapper",
                    severity: .warning,
                    confidence: .low,
                    suggestion:
                    "Create an AsyncStream<\(name)Event> that yields events instead of using delegate callbacks",
                ),
            )
        }

        private func isDelegateMethod(_ method: FunctionDeclSyntax) -> Bool {
            let name = method.name.text

            // Check for delegate naming patterns (case-insensitive for camelCase method names)
            let lowercaseName = name.lowercased()
            let hasCallbackName = Self.delegatePatterns.contains { lowercaseName.contains($0) }

            // Check for closure parameter (single callback shape)
            let hasClosureParam = method.signature.parameterClause.parameters.contains { param in
                param.type.trimmedDescription.contains("->")
                    || param.type.trimmedDescription.contains("@escaping")
            }

            return hasCallbackName || hasClosureParam
        }
    }
}
