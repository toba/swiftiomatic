import SwiftiomaticSyntax

struct FunctionParameterCountRule {
  static let id = "function_parameter_count"
  static let name = "Function Parameter Count"
  static let summary = "Number of function parameters should be low."
  static var nonTriggeringExamples: [Example] {
    [
      Example("init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
      Example("init (a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
      Example("`init`(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
      Example("init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
      Example("init?<T>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
      Example("init?<T: String>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
      Example("func f2(p1: Int, p2: Int) { }"),
      Example("func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}"),
      Example(
        """
        func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {
            let s = a.flatMap { $0 as? [String: Int] } ?? []}}
        """,
      ),
      Example("override func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
      Example("↓func initialValue(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
      Example(
        "private ↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}",
      ),
      Example(
        """
        struct Foo {
            init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
            ↓func bar(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}}
        """,
      ),
    ]
  }

  var options = FunctionParameterCountOptions()
}

extension FunctionParameterCountRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FunctionParameterCountRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      guard !node.modifiers.contains(keyword: .override) else {
        return
      }

      let parameterList = node.signature.parameterClause.parameters
      guard
        let minThreshold = configuration.severityConfiguration.params.map(\.value)
          .min(by: <)
      else {
        return
      }

      let allParameterCount = parameterList.count
      if allParameterCount < minThreshold {
        return
      }

      var parameterCount = allParameterCount
      if configuration.ignoresDefaultParameters {
        parameterCount -= parameterList.count(where: { $0.defaultValue != nil })
      }

      for parameter in configuration.severityConfiguration.params
      where parameterCount > parameter.value {
        let reason =
          "Function should have \(configuration.severityConfiguration.warning) parameters "
          + "or less: it currently has \(parameterCount)"

        violations.append(
          SyntaxViolation(
            position: node.funcKeyword.positionAfterSkippingLeadingTrivia,
            reason: reason,
            severity: parameter.severity,
          ),
        )
        return
      }
    }
  }
}
