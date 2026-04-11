import SwiftSyntax

struct FileMacroRule {
  static let id = "file_macro"
  static let name = "File Macro"
  static let summary = "Prefer `#file` over `#fileID` (identical in Swift 6+)"
  static let scope: Scope = .suggest
  static var nonTriggeringExamples: [Example] {
    [
      Example("func foo(file: StaticString = #file) {}")
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("func foo(file: StaticString = ↓#fileID) {}")
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension FileMacroRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FileMacroRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MacroExpansionExprSyntax) {
      if node.macroName.text == "fileID" {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
