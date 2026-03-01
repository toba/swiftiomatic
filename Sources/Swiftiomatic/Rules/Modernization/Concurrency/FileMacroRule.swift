import SwiftSyntax

struct FileMacroRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "file_macro",
    name: "File Macro",
    description: "Prefer `#file` over `#fileID` (identical in Swift 6+)",
    scope: .suggest,
    minSwiftVersion: .v6,
    nonTriggeringExamples: [
      Example("func foo(file: StaticString = #file) {}"),
    ],
    triggeringExamples: [
      Example("func foo(file: StaticString = ↓#fileID) {}"),
    ],
  )
}

extension FileMacroRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension FileMacroRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      if token.tokenKind == .poundAvailable || token.text == "#fileID" {
        // Check for #fileID keyword
        if case .keyword = token.tokenKind, token.text == "#fileID" {
          violations.append(token.positionAfterSkippingLeadingTrivia)
        }
      }
      // Also check raw token text for #fileID
      if token.text == "#fileID" {
        violations.append(token.positionAfterSkippingLeadingTrivia)
      }
      return .visitChildren
    }
  }
}
