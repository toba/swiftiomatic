import Foundation
import SwiftSyntax

struct AcronymsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = AcronymsConfiguration()
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
