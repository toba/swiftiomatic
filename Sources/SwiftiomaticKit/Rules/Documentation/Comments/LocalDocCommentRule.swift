import SwiftiomaticSyntax

struct LocalDocCommentRule: SwiftSyntaxRule {
  static let id = "local_doc_comment"
  static let name = "Local Doc Comment"
  static let summary = "Prefer regular comments over doc comments in local scopes"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        func foo() {
          // Local scope documentation should use normal comments.
          print("foo")
        }
        """,
      ),
      Example(
        """
        /// My great property
        var myGreatProperty: String!
        """,
      ),
      Example(
        """
        /// Look here for more info: https://github.com.
        var myGreatProperty: String!
        """,
      ),
      Example(
        """
        /// Look here for more info:
        /// https://github.com.
        var myGreatProperty: String!
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        func foo() {
          ↓/// Docstring inside a function declaration
          print("foo")
        }
        """,
      )
    ]
  }

  var options = SeverityOption<Self>(.warning)

  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(
      configuration: options,
      file: file,
      classifications: file.syntaxClassifications.filter { $0.kind != .none },
    )
  }
}

extension LocalDocCommentRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private let docCommentRanges: [Range<AbsolutePosition>]

    init(
      configuration: OptionsType,
      file: SwiftSource,
      classifications: [SyntaxClassifiedRange],
    ) {
      docCommentRanges =
        classifications
        .filter { $0.kind == .docLineComment || $0.kind == .docBlockComment }
        .map(\.range)
      super.init(configuration: configuration, file: file)
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      guard let body = node.body else {
        return
      }

      let violatingRange = docCommentRanges.first { $0.overlaps(body.range) }
      if let violatingRange {
        violations
          .append(AbsolutePosition(utf8Offset: violatingRange.lowerBound.utf8Offset))
      }
    }
  }
}
