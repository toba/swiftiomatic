import SwiftiomaticSyntax

struct PreferSourceLocationRule {
  static let id = "prefer_source_location"
  static let name = "Prefer SourceLocation"
  static let summary =
    "Test helpers should use `sourceLocation: SourceLocation` instead of separate file/line parameters"
  static let isCorrectable = true
  static var relatedRuleIDs: [String] { ["prefer_swift_testing_assertions"] }

  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        func assertValid(
          _ value: Int,
          sourceLocation: SourceLocation = #_sourceLocation
        ) { }
        """
      ),
      Example("func helper(file: String, line: Int) { }"),
      Example("func notTest(file: StaticString) { }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        func assertValid(
          _ value: Int,
          ↓file: StaticString = #filePath,
          line: UInt = #line
        ) { }
        """
      ),
      Example(
        """
        func assertValid(
          _ value: Int,
          ↓file: StaticString = #file,
          line: UInt = #line
        ) { }
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        func assertValid(
          _ value: Int,
          ↓file: StaticString = #filePath,
          line: UInt = #line
        ) { }
        """
      ): Example(
        """
        func assertValid(
          _ value: Int,
          sourceLocation: SourceLocation = #_sourceLocation
        ) { }
        """
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension PreferSourceLocationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferSourceLocationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      checkParameters(node.signature.parameterClause.parameters)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      checkParameters(node.signature.parameterClause.parameters)
    }

    private func checkParameters(_ params: FunctionParameterListSyntax) {
      let paramArray = Array(params)

      for i in 0..<paramArray.count {
        let param = paramArray[i]
        guard isFileParam(param),
          i + 1 < paramArray.count,
          isLineParam(paramArray[i + 1])
        else { continue }

        let fileParam = param
        let lineParam = paramArray[i + 1]

        // Build correction: replace from file param start to line param end
        let replacement = "sourceLocation: SourceLocation = #_sourceLocation"

        let correction = SyntaxViolation.Correction(
          start: fileParam.positionAfterSkippingLeadingTrivia,
          end: lineParam.endPositionBeforeTrailingTrivia,
          replacement: replacement,
        )

        violations.append(
          SyntaxViolation(
            position: fileParam.positionAfterSkippingLeadingTrivia,
            reason:
              "Separate file/line parameters can be replaced with sourceLocation: SourceLocation",
            correction: correction,
            confidence: .high,
            suggestion:
              "sourceLocation: SourceLocation = #_sourceLocation",
          )
        )
      }
    }

    private func isFileParam(_ param: FunctionParameterSyntax) -> Bool {
      let name = param.firstName.text
      guard name == "file" else { return false }
      guard param.type.trimmedDescription == "StaticString" else { return false }
      guard let defaultValue = param.defaultValue?.value.trimmedDescription else { return false }
      return defaultValue == "#filePath" || defaultValue == "#file"
    }

    private func isLineParam(_ param: FunctionParameterSyntax) -> Bool {
      let name = param.firstName.text
      guard name == "line" else { return false }
      guard param.type.trimmedDescription == "UInt" else { return false }
      guard let defaultValue = param.defaultValue?.value.trimmedDescription else { return false }
      return defaultValue == "#line"
    }
  }
}
