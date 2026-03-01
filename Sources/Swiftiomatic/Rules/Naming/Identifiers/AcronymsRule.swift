import SwiftSyntax

struct AcronymsRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "acronyms",
    name: "Acronyms",
    description: "Acronyms in identifiers should be uppercased (e.g. `URL` not `Url`)",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("let destinationURL: URL"),
      Example("let urlRouter: URLRouter"),
      Example("let screenIDs: [String]"),
    ],
    triggeringExamples: [
      Example("let ↓destinationUrl: URL"),
      Example("let ↓urlRouter: UrlRouter"),
      Example("let ↓screenIds: [String]"),
    ],
  )
}

extension AcronymsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension AcronymsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
        if name.contains(acronym) {
          violations.append(token.positionAfterSkippingLeadingTrivia)
          return
        }
      }
    }
  }
}
