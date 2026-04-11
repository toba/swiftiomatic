import Foundation
import SwiftSyntax

struct AcronymsRule {
  static let id = "acronyms"
  static let name = "Acronyms"
  static let summary = "Acronyms in identifiers should be uppercased (e.g. `URL` not `Url`)"
  static let scope: Scope = .suggest
  static var nonTriggeringExamples: [Example] {
    [
      Example("let destinationURL: URL"),
      Example("let urlRouter: URLRouter"),
      Example("let screenIDs: [String]"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let ↓destinationUrl: URL"),
      Example("let ↓myUrlRouter: URLRouter"),
      Example("let ↓screenId: String"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension AcronymsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AcronymsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private static let commonAcronyms: Set<String> = [
      "Id", "Url", "Uri", "Http", "Https", "Ftp", "Ssh", "Json", "Xml",
      "Html", "Css", "Sql", "Api", "Uuid", "Utf",
    ]

    override func visitPost(_ node: IdentifierPatternSyntax) {
      checkIdentifier(node.identifier)
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      checkIdentifier(node.name)
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      checkIdentifier(node.name)
    }

    private func checkIdentifier(_ token: TokenSyntax) {
      let name = token.text
      guard name.first?.isLetter == true else { return }

      for acronym in Self.commonAcronyms {
        guard let range = name.range(of: acronym) else { continue }
        // Ensure word boundary: next char must be uppercase, end-of-string, or absent
        let afterEnd = range.upperBound
        if afterEnd == name.endIndex || name[afterEnd].isUppercase {
          violations.append(token.positionAfterSkippingLeadingTrivia)
          return
        }
      }
    }
  }
}
