//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@testable import Swiftiomatic
import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

@Suite
struct DocumentationCommentTextTests {
  @Test func simpleDocLineComment() throws {
    let decl: DeclSyntax = """
      /// A simple doc comment.
      func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .line)
    #expect(
      commentText.text
        == """
        A simple doc comment.

        """
    )
  }

  @Test func oneLineDocBlockComment() throws {
    let decl: DeclSyntax = """
      /** A simple doc comment. */
      func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(
      commentText.text
        == """
        A simple doc comment.\u{0020}

        """
    )
  }

  @Test func docBlockCommentWithASCIIArt() throws {
    let decl: DeclSyntax = """
      /**
       * A simple doc comment.
       */
      func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(
      commentText.text
        == """
        A simple doc comment.

        """
    )
  }

  @Test func indentedDocBlockCommentWithASCIIArt() throws {
    let decl: DeclSyntax = """
        /**
         * A simple doc comment.
         */
        func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(
      commentText.text
        == """
        A simple doc comment.

        """
    )
  }

  @Test func docBlockCommentWithoutASCIIArt() throws {
    let decl: DeclSyntax = """
      /**
         A simple doc comment.
       */
      func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(
      commentText.text
        == """
        A simple doc comment.

        """
    )
  }

  @Test func multilineDocLineComment() throws {
    let decl: DeclSyntax = """
      /// A doc comment.
      ///
      /// This is a longer paragraph,
      /// containing more detail.
      ///
      /// - Parameter x: A parameter.
      /// - Returns: A value.
      func f(x: Int) -> Int {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .line)
    #expect(
      commentText.text
        == """
        A doc comment.

        This is a longer paragraph,
        containing more detail.

        - Parameter x: A parameter.
        - Returns: A value.

        """
    )
  }

  @Test func docLineCommentStopsAtBlankLine() throws {
    let decl: DeclSyntax = """
      /// This should not be part of the comment.

      /// A doc comment.
      func f(x: Int) -> Int {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .line)
    #expect(
      commentText.text
        == """
        A doc comment.

        """
    )
  }

  @Test func docBlockCommentStopsAtBlankLine() throws {
    let decl: DeclSyntax = """
      /** This should not be part of the comment. */

      /**
       * This is part of the comment.
       */
      /** so is this */
      func f(x: Int) -> Int {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(
      commentText.text
        == """
        This is part of the comment.
         so is this\u{0020}

        """
    )
  }

  @Test func docCommentHasMixedIntroducers() throws {
    let decl: DeclSyntax = """
      /// This is part of the comment.
      /** This is too. */
      func f(x: Int) -> Int {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .mixed)
    #expect(
      commentText.text
        == """
        This is part of the comment.
        This is too.\u{0020}

        """
    )
  }

  @Test func nilIfNoComment() throws {
    let decl: DeclSyntax = """
      func f(x: Int) -> Int {}
      """
    #expect(DocumentationCommentText(extractedFrom: decl.leadingTrivia) == nil)
  }
}
