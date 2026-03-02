struct SwitchCaseOnNewlineConfiguration: RuleConfiguration {
    let id = "switch_case_on_newline"
    let name = "Cases on Newline"
    let summary = "Cases inside a switch should always be on a newline"
    let isOptIn = true

    private static func wrapInSwitch(_ str: String, file: StaticString = #filePath, line: UInt = #line)
      -> Example
    {
      Example(
        """
        switch foo {
            \(str)
        }
        """, file: file, line: line,
      )
    }

    var nonTriggeringExamples: [Example] {
        [
              Example("/*case 1: */return true"),
              Example("//case 1:\n return true"),
              Example("let x = [caseKey: value]"),
              Example("let x = [key: .default]"),
              Example("if case let .someEnum(value) = aFunction([key: 2]) { }"),
              Example("guard case let .someEnum(value) = aFunction([key: 2]) { }"),
              Example("for case let .someEnum(value) = aFunction([key: 2]) { }"),
              Example("enum Environment {\n case development\n}"),
              Example("enum Environment {\n case development(url: URL)\n}"),
              Example("enum Environment {\n case development(url: URL) // staging\n}"),

              Self.wrapInSwitch("case 1:\n return true"),
              Self.wrapInSwitch("default:\n return true"),
              Self.wrapInSwitch("case let value:\n return true"),
              Self.wrapInSwitch("case .myCase: // error from network\n return true"),
              Self.wrapInSwitch("case let .myCase(value) where value > 10:\n return false"),
              Self.wrapInSwitch("case let .myCase(value)\n where value > 10:\n return false"),
              Self.wrapInSwitch(
                """
                case let .myCase(code: lhsErrorCode, description: _)
                 where lhsErrorCode > 10:
                return false
                """,
              ),
              Self.wrapInSwitch("case #selector(aFunction(_:)):\n return false"),
              Example(
                """
                do {
                  let loadedToken = try tokenManager.decodeToken(from: response)
                  return loadedToken
                } catch { throw error }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Self.wrapInSwitch("↓case 1: return true"),
              Self.wrapInSwitch("↓case let value: return true"),
              Self.wrapInSwitch("↓default: return true"),
              Self.wrapInSwitch("↓case \"a string\": return false"),
              Self.wrapInSwitch("↓case .myCase: return false // error from network"),
              Self.wrapInSwitch("↓case let .myCase(value) where value > 10: return false"),
              Self.wrapInSwitch("↓case #selector(aFunction(_:)): return false"),
              Self.wrapInSwitch("↓case let .myCase(value)\n where value > 10: return false"),
              Self.wrapInSwitch("↓case .first,\n .second: return false"),
            ]
    }
}
