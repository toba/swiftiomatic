import SwiftIDEUtils
import SwiftSyntax
import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct SyntaxKindMapperTests {
  @Test func basicKeywordMapping() {
    // Test basic keyword mappings
    #expect(SyntaxKindMapper.mapClassification(.keyword) == .keyword)
  }

  @Test func identifierMapping() {
    // Test identifier mappings
    #expect(SyntaxKindMapper.mapClassification(.identifier) == .identifier)
    #expect(SyntaxKindMapper.mapClassification(.dollarIdentifier) == .identifier)
  }

  @Test func commentMapping() {
    // Test comment mappings
    #expect(SyntaxKindMapper.mapClassification(.lineComment) == .comment)
    #expect(SyntaxKindMapper.mapClassification(.blockComment) == .comment)
    #expect(SyntaxKindMapper.mapClassification(.docLineComment) == .docComment)
    #expect(SyntaxKindMapper.mapClassification(.docBlockComment) == .docComment)
  }

  @Test func literalMapping() {
    // Test literal mappings
    #expect(SyntaxKindMapper.mapClassification(.stringLiteral) == .string)
    #expect(SyntaxKindMapper.mapClassification(.integerLiteral) == .number)
    #expect(SyntaxKindMapper.mapClassification(.floatLiteral) == .number)
  }

  @Test func operatorAndTypeMapping() {
    // Test operator and type mappings
    #expect(SyntaxKindMapper.mapClassification(.operator) == .operator)
    #expect(SyntaxKindMapper.mapClassification(.type) == .typeidentifier)
  }

  @Test func specialCaseMapping() {
    // Test special case mappings
    #expect(SyntaxKindMapper.mapClassification(.attribute) == .attributeID)
    #expect(SyntaxKindMapper.mapClassification(.editorPlaceholder) == .placeholder)
    #expect(
      SyntaxKindMapper
        .mapClassification(.ifConfigDirective) == .poundDirectiveKeyword)
    #expect(SyntaxKindMapper.mapClassification(.argumentLabel) == .argument)
  }

  @Test func unmappedClassifications() {
    // Test classifications that have no mapping
    #expect(SyntaxKindMapper.mapClassification(.none) == nil)
    #expect(SyntaxKindMapper.mapClassification(.regexLiteral) == nil)
  }

  @Test func sourceKitSyntaxKindsGeneration() {
    // Test that we can generate SourceKit-compatible tokens from a simple Swift file
    let contents = """
      // This is a comment
      let x = 42
      """
    let file = SwiftSource(contents: contents)

    // Get the tokens from the bridge
    let tokens = SyntaxKindMapper.sourceKitSyntaxKinds(for: file)

    // Verify we got some tokens
    #expect(!(tokens.isEmpty))

    // Check that we have expected token types
    let tokenTypes = Set(tokens.map(\.token.type))
    #expect(tokenTypes.contains(SourceKitSyntaxKind.comment.rawValue))
    #expect(tokenTypes.contains(SourceKitSyntaxKind.keyword.rawValue))
    #expect(tokenTypes.contains(SourceKitSyntaxKind.identifier.rawValue))
    #expect(tokenTypes.contains(SourceKitSyntaxKind.number.rawValue))
  }

  @Test func tokenOffsetAndLength() {
    // Test that token offsets and lengths are correct
    let contents = "let x = 42"
    let file = SwiftSource(contents: contents)

    let tokens = SyntaxKindMapper.sourceKitSyntaxKinds(for: file)

    // Find the "let" keyword token
    let letToken = tokens.first { token in
      if token.token.type == SourceKitSyntaxKind.keyword.rawValue {
        let start = token.token.offset.value
        let end = token.token.offset.value + token.token.length.value
        let startIndex = contents.index(contents.startIndex, offsetBy: start)
        let endIndex = contents.index(contents.startIndex, offsetBy: end)
        let substring = String(contents[startIndex..<endIndex])
        return substring == "let"
      }
      return false
    }
    #expect(letToken != nil)
    #expect(letToken?.token.offset.value == 0)
    #expect(letToken?.token.length.value == 3)

    // Find the number token
    let numberToken = tokens.first { $0.token.type == SourceKitSyntaxKind.number.rawValue }
    #expect(numberToken != nil)
    // "42" starts at offset 8 and has length 2
    #expect(numberToken?.token.offset.value == 8)
    #expect(numberToken?.token.length.value == 2)
  }

  @Test func complexCodeStructure() {
    // Test with more complex Swift code
    let contents = """

      /// A sample class
      @objc
      class MyClass {
          // Properties
          var name: String = "test"
          let id = UUID()

          func doSomething() {
              print("Hello, \\(name)!")
          }
      }
      """
    let file = SwiftSource(contents: contents)

    let tokens = SyntaxKindMapper.sourceKitSyntaxKinds(for: file)

    // Verify we have various token types
    let tokenTypes = Set(tokens.map(\.token.type))
    #expect(tokenTypes.contains(SourceKitSyntaxKind.keyword.rawValue))  // import, class, var, let, func
    #expect(
      tokenTypes
        .contains(SourceKitSyntaxKind.identifier.rawValue))  // Foundation, MyClass, name, etc.
    #expect(tokenTypes.contains(SourceKitSyntaxKind.docComment.rawValue))  // /// A sample class
    #expect(tokenTypes.contains(SourceKitSyntaxKind.comment.rawValue))  // // Properties
    #expect(tokenTypes.contains(SourceKitSyntaxKind.attributeID.rawValue))  // @objc
    #expect(tokenTypes.contains(SourceKitSyntaxKind.typeidentifier.rawValue))  // String, UUID
    #expect(tokenTypes.contains(SourceKitSyntaxKind.string.rawValue))  // "test", "Hello, \\(name)!"
  }

  @Test func noSourceKitCallsAreMade() {
    // This test verifies that the bridge doesn't make any SourceKit calls
    // If it did, the validation system would fatal error in test mode

    let contents = """
      struct Test {
          let value = 123
          func method() -> Int { return value }
      }
      """
    let file = SwiftSource(contents: contents)

    // This should succeed without any fatal errors from the validation system
    let tokens = SyntaxKindMapper.sourceKitSyntaxKinds(for: file)
    #expect(!(tokens.isEmpty))
  }

  @Test func emptyFileHandling() {
    // Test that empty files are handled gracefully
    let file = SwiftSource(contents: "")
    let tokens = SyntaxKindMapper.sourceKitSyntaxKinds(for: file)
    #expect(tokens.isEmpty)
  }

  @Test func whitespaceOnlyFile() {
    // Test files with only whitespace
    let file = SwiftSource(contents: "   \n\n  \t  \n")
    let tokens = SyntaxKindMapper.sourceKitSyntaxKinds(for: file)
    // Whitespace is not classified, so we should get no tokens
    #expect(tokens.isEmpty)
  }
}
