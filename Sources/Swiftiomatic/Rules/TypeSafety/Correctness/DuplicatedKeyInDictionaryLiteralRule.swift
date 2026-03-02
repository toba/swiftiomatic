import SwiftSyntax

struct DuplicatedKeyInDictionaryLiteralRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = DuplicatedKeyInDictionaryLiteralConfiguration()
}

extension DuplicatedKeyInDictionaryLiteralRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DuplicatedKeyInDictionaryLiteralRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ list: DictionaryElementListSyntax) {
      let keys = list.map(\.key).compactMap { expr -> DictionaryKey? in
        expr.stringContent.map {
          DictionaryKey(position: expr.positionAfterSkippingLeadingTrivia, content: $0)
        }
      }

      guard keys.count >= 2 else {
        return
      }

      let newViolations =
        keys
        .reduce(into: [String: [DictionaryKey]]()) { result, key in
          result[key.content, default: []].append(key)
        }
        .flatMap { _, value -> [AbsolutePosition] in
          guard value.count > 1 else {
            return []
          }

          return value.dropFirst().map(\.position)
        }

      violations.append(contentsOf: newViolations)
    }
  }
}

private struct DictionaryKey {
  let position: AbsolutePosition
  let content: String
}

extension ExprSyntax {
  fileprivate var stringContent: String? {
    if let string = `as`(StringLiteralExprSyntax.self) {
      return string.description
    }
    if let int = `as`(IntegerLiteralExprSyntax.self) {
      return int.description
    }
    if let float = `as`(FloatLiteralExprSyntax.self) {
      return float.description
    }
    if let memberAccess = `as`(MemberAccessExprSyntax.self) {
      return memberAccess.description
    }
    if let identifier = `as`(DeclReferenceExprSyntax.self) {
      return identifier.baseName.text
    }

    return nil
  }
}
