import Foundation

extension Request {
  /// Send this SourceKit request after verifying the current rule is allowed to use SourceKit
  ///
  /// Guards against accidental SourceKit use by ``SyntaxOnlyRule`` conformances and
  /// requests made outside of a rule execution context. Calls ``Console/fatalError(_:)``
  /// when a violation is detected.
  func sendIfNotDisabled() throws(Request.Error) -> [String: SourceKitValue] {
    // Skip safety checks if explicitly allowed (e.g., for testing or specific operations)
    if !CurrentRule.allowSourceKitRequestWithoutRule {
      // Check if we have a rule context
      if let ruleID = CurrentRule.identifier {
        // Skip registry check for mock test rules
        if ruleID != "mock_test_rule_for_swiftlint_tests" {
          // Ensure the rule exists in the registry
          guard let ruleType = RuleRegistry.shared.rule(forID: ruleID) else {
            Console.fatalError(
              """
              Rule '\(
                                ruleID
                            )' not found in RuleRegistry. This indicates a configuration or wiring issue.
              """,
            )
          }

          // Check if the current rule does not require SourceKit
          if !ruleType.description.requiresSourceKit {
            Console.fatalError(
              """
              '\(
                                ruleID
                            )' is a SyntaxOnlyRule and should not be making requests to SourceKit.
              """,
            )
          }
        }
      } else {
        // No rule context — allow but warn (non-fatal to support parallel test execution
        // where @TaskLocal context may not propagate through all dispatch paths)
        Console.printError(
          """
          warning: SourceKit request made outside of rule execution context. \
          Use CurrentRule.$allowSourceKitRequestWithoutRule.withValue(true) { ... } for explicit allowance.
          """,
        )
      }
    }

    return try send()
  }

  /// Build a cursor-info request with symbol-graph retrieval disabled
  ///
  /// Omitting the symbol graph significantly reduces SourceKit response time when only
  /// basic cursor information (kind, USR, type) is needed.
  ///
  /// - Parameters:
  ///   - file: Absolute path to the source file.
  ///   - offset: Byte offset of the cursor position within the file.
  ///   - arguments: Compiler arguments forwarded to SourceKit.
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
