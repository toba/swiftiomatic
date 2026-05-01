import SwiftSyntax

/// XCTestCase subclasses should be `final` .
///
/// Marking a test case `final` lets the runtime resolve test methods statically and avoids the
/// dynamic-dispatch overhead Apple's docs call out for non-final test cases.
///
/// Lint: warns on a `class` (not `final` , not `open` ) that inherits from a known test base class
/// ( `XCTestCase` , `QuickSpec` ).
final class FinalTestCase: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .testing }

    private static let testParentClasses: Set<String> = ["XCTestCase", "QuickSpec"]

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !node.modifiers.contains(.final),
              !node.modifiers.contains(.open),
              let inheritance = node.inheritanceClause,
              inheritance.inheritedTypes.contains(where: { inherited in
                  guard let identType = inherited.type.as(IdentifierTypeSyntax.self) else {
                      return false
                  }
                  return Self.testParentClasses.contains(identType.name.text)
              }) else { return .visitChildren }
        diagnose(.finalTestCase, on: node.name)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let finalTestCase: Finding.Message = "test cases should be 'final'"
}
