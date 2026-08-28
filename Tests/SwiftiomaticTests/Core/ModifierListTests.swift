import Testing
import SwiftParser
import SwiftSyntax
@testable import SwiftiomaticKit

@Suite struct ModifierListTests {
    /// Parses `source` and returns its single top-level declaration.
    private func firstDecl(_ source: String) throws -> DeclSyntax {
        let file = Parser.parse(source: source)
        let item = try #require(file.statements.first?.item)
        return try #require(item.as(DeclSyntax.self))
    }

    @Test func removesModifierFromFunction() throws {
        let result = try firstDecl("public func f() { }").removingModifiers([.public])
        #expect(!result.description.contains("public"))
    }

    /// `modifiersOrNil` reports the modifiers of an extension, so the removal counterpart has to
    /// handle the same kind. It returned the extension unchanged.
    @Test func removesModifierFromExtension() throws {
        let result = try firstDecl("public extension Foo { }").removingModifiers([.public])
        #expect(!result.description.contains("public"))
        #expect(result.description.contains("extension Foo"))
    }

    @Test func keepsUnmatchedModifier() throws {
        let result = try firstDecl("final class C { }").removingModifiers([.public])
        #expect(result.description.contains("final"))
    }
}
