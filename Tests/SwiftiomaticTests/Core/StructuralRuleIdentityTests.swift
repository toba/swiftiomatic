@testable import SwiftiomaticKit
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
import Testing

/// A `StructuralFormatRule` that changes nothing returns its input node, so the format pass does
/// not rebuild the tree for a file that the rule leaves as it is.
@Suite
struct StructuralRuleIdentityTests {
  private func context(_ tree: SourceFileSyntax, configuration: Configuration) -> Context {
    makeTestContext(
      sourceFileSyntax: tree,
      configuration: configuration,
      selection: .infinite,
      findingConsumer: { _ in }
    )
  }

  @Test func useFilePrivateForFileLocalReturnsInputWhenNothingChanges() throws {
    let tree = Parser.parse(
      source: """
        #if DEBUG
        func a() {}
        #endif
        struct B { private var c = 1 }
        private let d = 2
        """
    )
    var configuration = Configuration.forTesting(enabledRule: UseFilePrivateForFileLocal.key)
    configuration[UseFilePrivateForFileLocal.self].accessLevel = .private
    let rule = UseFilePrivateForFileLocal(context: context(tree, configuration: configuration))

    #expect(rule.visit(tree).id == tree.id)
  }

  @Test func useFilePrivateForFileLocalRewritesWhenAModifierChanges() throws {
    let tree = Parser.parse(source: "#if DEBUG\nfileprivate func a() {}\n#endif\n")
    var configuration = Configuration.forTesting(enabledRule: UseFilePrivateForFileLocal.key)
    configuration[UseFilePrivateForFileLocal.self].accessLevel = .private
    let rule = UseFilePrivateForFileLocal(context: context(tree, configuration: configuration))

    #expect(rule.visit(tree).description == "#if DEBUG\nprivate func a() {}\n#endif\n")
  }
}
