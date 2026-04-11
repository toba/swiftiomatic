import SwiftSyntax

struct SwitchCaseOnNewlineRule {
  static let id = "switch_case_on_newline"
  static let name = "Cases on Newline"
  static let summary = "Cases inside a switch should always be on a newline"
  static let isOptIn = true

  private static func wrapInSwitch(
    _ str: String, file: StaticString = #filePath, line: UInt = #line,
  )
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

  static var nonTriggeringExamples: [Example] {
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

      wrapInSwitch("case 1:\n return true"),
      wrapInSwitch("default:\n return true"),
      wrapInSwitch("case let value:\n return true"),
      wrapInSwitch("case .myCase: // error from network\n return true"),
      wrapInSwitch("case let .myCase(value) where value > 10:\n return false"),
      wrapInSwitch("case let .myCase(value)\n where value > 10:\n return false"),
      wrapInSwitch(
        """
        case let .myCase(code: lhsErrorCode, description: _)
         where lhsErrorCode > 10:
        return false
        """,
      ),
      wrapInSwitch("case #selector(aFunction(_:)):\n return false"),
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

  static var triggeringExamples: [Example] {
    [
      wrapInSwitch("↓case 1: return true"),
      wrapInSwitch("↓case let value: return true"),
      wrapInSwitch("↓default: return true"),
      wrapInSwitch("↓case \"a string\": return false"),
      wrapInSwitch("↓case .myCase: return false // error from network"),
      wrapInSwitch("↓case let .myCase(value) where value > 10: return false"),
      wrapInSwitch("↓case #selector(aFunction(_:)): return false"),
      wrapInSwitch("↓case let .myCase(value)\n where value > 10: return false"),
      wrapInSwitch("↓case .first,\n .second: return false"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SwitchCaseOnNewlineRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SwitchCaseOnNewlineRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseSyntax) {
      let caseEndLine =
        locationConverter
        .location(for: node.label.endPositionBeforeTrailingTrivia)
        .line
      let statementsPosition = node.statements.positionAfterSkippingLeadingTrivia
      let statementStartLine = locationConverter.location(for: statementsPosition).line
      if statementStartLine == caseEndLine {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
