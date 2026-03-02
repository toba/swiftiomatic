import SwiftSyntax

/// Rule to require all classes to have a deinit method
///
/// An example of when this is useful is if the project does allocation tracking
/// of objects and the deinit should print a message or remove its instance from a
/// list of allocations. Even having an empty deinit method is useful to provide
/// a place to put a breakpoint when chasing down leaks.
struct RequiredDeinitRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RequiredDeinitConfiguration()
}

extension RequiredDeinitRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RequiredDeinitRule {}

extension RequiredDeinitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClassDeclSyntax) {
      let visitor = DeinitVisitor(configuration: configuration, file: file)
      if !visitor.walk(tree: node.memberBlock, handler: \.hasDeinit) {
        violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class DeinitVisitor: ViolationCollectingVisitor<OptionsType> {
    private(set) var hasDeinit = false

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_: DeinitializerDeclSyntax) {
      hasDeinit = true
    }
  }
}
