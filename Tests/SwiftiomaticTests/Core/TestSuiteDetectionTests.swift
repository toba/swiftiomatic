import Testing
import SwiftParser
import SwiftSyntax
@testable import SwiftiomaticKit

@Suite struct TestSuiteDetectionTests {
    /// Parses `source` and runs `isTestSuite` over its single struct declaration.
    private func suite(_ source: String) throws -> Bool {
        let file = Parser.parse(source: source)
        let item = try #require(file.statements.first?.item)
        let decl = try #require(item.as(StructDeclSyntax.self))
        return isTestSuite(
            name: decl.name.text,
            inheritanceClause: decl.inheritanceClause,
            modifiers: decl.modifiers,
            leadingTrivia: decl.leadingTrivia,
            framework: .swiftTesting
        )
    }

    @Test func detectsPlainSuite() throws { #expect(try suite("struct ParserTests { }")) }

    @Test func skipsTypeWithoutTestSuffix() throws { #expect(try !suite("struct Parser { }")) }

    // MARK: - Base-class exclusion

    @Test func skipsTypeNamedForABaseClass() throws { #expect(try !suite("struct BaseTests { }")) }

    @Test func skipsTypeDocumentedAsABaseClass() throws {
        #expect(try !suite("/// A base class for the parser suites.\nstruct HarnessTests { }"))
    }

    @Test func skipsTypeDocumentedAsSubclassed() throws {
        #expect(try !suite("/// Subclass this to add cases.\nstruct HarnessTests { }"))
    }

    /// `base` inside a longer word does not mark a base class. Matching it as a substring hid every
    /// suite whose documentation mentions a database.
    @Test func detectsSuiteWhoseDocMentionsADatabase() throws {
        #expect(try suite("/// Tests the database layer.\nstruct StorageTests { }"))
    }

    /// `Base` inside a longer word does not mark a base class either.
    @Test func detectsSuiteWhoseNameStartsWithABaseWord() throws {
        #expect(try suite("struct BaseballTests { }"))
    }
}
