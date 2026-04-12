import SwiftiomaticSyntax

struct DuplicatedKeyInDictionaryLiteralRule {
  static let id = "duplicated_key_in_dictionary_literal"
  static let name = "Duplicated Key in Dictionary Literal"
  static let summary = "Dictionary literals with duplicated keys will crash at runtime"
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        [
            1: "1",
            2: "2"
        ]
        """,
      ),
      Example(
        """
        [
            "1": 1,
            "2": 2
        ]
        """,
      ),
      Example(
        """
        [
            foo: "1",
            bar: "2"
        ]
        """,
      ),
      Example(
        """
        [
            UUID(): "1",
            UUID(): "2"
        ]
        """,
      ),
      Example(
        """
        [
            #line: "1",
            #line: "2"
        ]
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        [
            1: "1",
            2: "2",
            ↓1: "one"
        ]
        """,
      ),
      Example(
        """
        [
            "1": 1,
            "2": 2,
            ↓"2": 2
        ]
        """,
      ),
      Example(
        """
        [
            foo: "1",
            bar: "2",
            baz: "3",
            ↓foo: "4",
            zaz: "5"
        ]
        """,
      ),
      Example(
        """
        [
            .one: "1",
            .two: "2",
            .three: "3",
            ↓.one: "1",
            .four: "4",
            .five: "5"
        ]
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
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
