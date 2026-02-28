import Foundation

extension Request {
    func sendIfNotDisabled() throws -> [String: SourceKitValue] {
        // Skip safety checks if explicitly allowed (e.g., for testing or specific operations)
        if !CurrentRule.allowSourceKitRequestWithoutRule {
            // Check if we have a rule context
            if let ruleID = CurrentRule.identifier {
                // Skip registry check for mock test rules
                if ruleID != "mock_test_rule_for_swiftlint_tests" {
                    // Ensure the rule exists in the registry
                    guard let ruleType = RuleRegistry.shared.rule(forID: ruleID) else {
                        queuedFatalError(
                            """
                            Rule '\(
                                ruleID
                            )' not found in RuleRegistry. This indicates a configuration or wiring issue.
                            """,
                        )
                    }

                    // Check if the current rule is a SourceKitFreeRule
                    // Skip check for ConditionallySourceKitFree rules since we can't determine
                    // at the type level if they're effectively SourceKit-free
                    if ruleType is any SourceKitFreeRule.Type,
                       !(ruleType is any ConditionallySourceKitFree.Type)
                    {
                        queuedFatalError(
                            """
                            '\(
                                ruleID
                            )' is a SourceKitFreeRule and should not be making requests to SourceKit.
                            """,
                        )
                    }
                }
            } else {
                // No rule context — allow but warn (non-fatal to support parallel test execution
                // where @TaskLocal context may not propagate through all dispatch paths)
                queuedPrintError(
                    """
                    warning: SourceKit request made outside of rule execution context. \
                    Use CurrentRule.$allowSourceKitRequestWithoutRule.withValue(true) { ... } for explicit allowance.
                    """,
                )
            }
        }

        return try send()
    }

    static func cursorInfoWithoutSymbolGraph(file: String, offset: ByteCount, arguments: [String])
        -> Request
    {
        .customRequest(request: [
            "key.request": UID("source.request.cursorinfo"),
            "key.name": file,
            "key.sourcefile": file,
            "key.offset": Int64(offset.value),
            "key.compilerargs": arguments,
            "key.cancel_on_subsequent_request": 0,
            "key.retrieve_symbol_graph": 0,
        ])
    }
}
