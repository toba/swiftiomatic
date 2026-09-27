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

@Suite struct TestSuiteDetectionXCTestTests {
    /// Parses `source` and runs `isTestSuite` for XCTest over its single class declaration.
    private func suite(_ source: String) throws -> Bool {
        let file = Parser.parse(source: source)
        let item = try #require(file.statements.first?.item)
        let decl = try #require(item.as(ClassDeclSyntax.self))
        return isTestSuite(
            name: decl.name.text,
            inheritanceClause: decl.inheritanceClause,
            modifiers: decl.modifiers,
            leadingTrivia: decl.leadingTrivia,
            framework: .xcTest
        )
    }

    @Test func detectsXCTestCaseSubclass() throws {
        #expect(try suite("class ParserTests: XCTestCase { }"))
    }

    /// The compare is on the full type text, so a module-qualified base class does not match.
    @Test func skipsQualifiedXCTestCase() throws {
        #expect(try !suite("class ParserTests: XCTest.XCTestCase { }"))
    }

    @Test func skipsGenericBase() throws {
        #expect(try !suite("class ParserTests: XCTestCase<Int> { }"))
    }

    /// The doc comment check ignores case.
    @Test func skipsMixedCaseBaseDocComment() throws {
        #expect(try !suite("/// A BASE Class for suites.\nclass ParserTests: XCTestCase { }"))
        #expect(try !suite("/// SubClass this.\nclass ParserTests: XCTestCase { }"))
        #expect(try !suite("/* Base */\nclass ParserTests: XCTestCase { }"))
    }

    @Test func detectsMixedCaseDatabaseDocComment() throws {
        #expect(try suite("/// Tests the DataBase layer.\nclass ParserTests: XCTestCase { }"))
        #expect(try suite("/// Tests the BASEMENT.\nclass ParserTests: XCTestCase { }"))
    }

    /// A word in a comment above an earlier blank line still counts.
    @Test func skipsBaseWordAnywhereInLeadingTrivia() throws {
        #expect(try !suite("// base\n\n/// Suite.\nclass ParserTests: XCTestCase { }"))
    }
}
