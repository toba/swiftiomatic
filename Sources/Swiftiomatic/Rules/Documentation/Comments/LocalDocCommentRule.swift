import SwiftIDEUtils
import SwiftSyntax

struct LocalDocCommentRule: SwiftSyntaxRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "local_doc_comment",
    name: "Local Doc Comment",
    description: "Prefer regular comments over doc comments in local scopes",
    isOptIn: true,
    nonTriggeringExamples: [
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
    ],
    triggeringExamples: [
      Example(
        """
        func foo() {
          ↓/// Docstring inside a function declaration
          print("foo")
        }
        """,
      )
    ],
  )

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
