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

import Markdown
@testable import SwiftiomaticKit
import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

@Suite
struct DocumentationCommentTests {
  @Test func briefSummaryOnly() throws {
    let decl: DeclSyntax = """
      /// A brief summary.
      func f() {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(
      try #require(comment.briefSummary).debugDescription()
        == """
        Paragraph
        └─ Text "A brief summary."
        """
    )
    #expect(comment.bodyNodes.isEmpty)
    #expect(comment.parameterLayout == nil)
    #expect(comment.parameters.isEmpty)
    #expect(comment.returns == nil)
    #expect(comment.throws == nil)
  }

  @Test func briefSummaryAndAdditionalParagraphs() throws {
    let decl: DeclSyntax = """
      /// A brief summary.
      ///
      /// Some detail.
      ///
      /// More detail.
      func f() {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(
      comment.briefSummary?.debugDescription()
        == """
        Paragraph
        └─ Text "A brief summary."
        """
    )
    #expect(
      comment.bodyNodes.map { $0.debugDescription() }
        == [
          """
          Paragraph
          └─ Text "Some detail."
          """,
          """
          Paragraph
          └─ Text "More detail."
          """,
        ]
    )
    #expect(comment.parameterLayout == nil)
    #expect(comment.parameters.isEmpty)
    #expect(comment.returns == nil)
    #expect(comment.throws == nil)
  }

  @Test func parameterOutline() throws {
    let decl: DeclSyntax = """
      /// - Parameters:
      ///   - x: A value.
      ///   - y: Another value.
      func f(x: Int, y: Int) {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(comment.briefSummary == nil)
    #expect(comment.bodyNodes.isEmpty)
    #expect(comment.parameterLayout == .outline)
    #expect(comment.parameters.count == 2)
    #expect(comment.parameters[0].name == "x")
    #expect(
      comment.parameters[0].comment.briefSummary?.debugDescription()
        == """
        Paragraph
        └─ Text " A value."
        """
    )
    #expect(comment.parameters[1].name == "y")
    #expect(
      comment.parameters[1].comment.briefSummary?.debugDescription()
        == """
        Paragraph
        └─ Text " Another value."
        """
    )
    #expect(comment.returns == nil)
    #expect(comment.throws == nil)
  }

  @Test func separatedParameters() throws {
    let decl: DeclSyntax = """
      /// - Parameter x: A value.
      /// - Parameter y: Another value.
      func f(x: Int, y: Int) {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(comment.briefSummary == nil)
    #expect(comment.bodyNodes.isEmpty)
    #expect(comment.parameterLayout == .separated)
    #expect(comment.parameters.count == 2)
    #expect(comment.parameters[0].name == "x")
    #expect(
      comment.parameters[0].comment.briefSummary?.debugDescription()
        == """
        Paragraph
        └─ Text " A value."
        """
    )
    #expect(comment.parameters[1].name == "y")
    #expect(
      comment.parameters[1].comment.briefSummary?.debugDescription()
        == """
        Paragraph
        └─ Text " Another value."
        """
    )
    #expect(comment.returns == nil)
    #expect(comment.throws == nil)
  }

  @Test func malformedTagsGoIntoBodyNodes() throws {
    let decl: DeclSyntax = """
      /// - Parameter: A value.
      /// - Parameter y Another value.
      /// - Parmeter z: Another value.
      /// - Parameter *x*: Another value.
      /// - Return: A value.
      /// - Throw: An error.
      func f(x: Int, y: Int) {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(comment.bodyNodes.count == 1)
    #expect(
      comment.bodyNodes[0].debugDescription()
        == """
        UnorderedList
        ├─ ListItem
        │  └─ Paragraph
        │     └─ Text "Parameter: A value."
        ├─ ListItem
        │  └─ Paragraph
        │     └─ Text "Parameter y Another value."
        ├─ ListItem
        │  └─ Paragraph
        │     └─ Text "Parmeter z: Another value."
        ├─ ListItem
        │  └─ Paragraph
        │     ├─ Text "Parameter "
        │     ├─ Emphasis
        │     │  └─ Text "x"
        │     └─ Text ": Another value."
        ├─ ListItem
        │  └─ Paragraph
        │     └─ Text "Return: A value."
        └─ ListItem
           └─ Paragraph
              └─ Text "Throw: An error."
        """
    )
    #expect(comment.parameterLayout == nil)
    #expect(comment.parameters.isEmpty)
  }

  @Test func returnsField() throws {
    let decl: DeclSyntax = """
      /// - Returns: A value.
      func f() {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(comment.briefSummary == nil)
    #expect(comment.bodyNodes.isEmpty)
    #expect(comment.parameterLayout == nil)
    #expect(comment.parameters.isEmpty)

    let returnsField = try #require(comment.returns)
    #expect(
      returnsField.debugDescription()
        == """
        Paragraph
        └─ Text " A value."
        """
    )
    #expect(comment.throws == nil)
  }

  @Test func throwsField() throws {
    let decl: DeclSyntax = """
      /// - Throws: An error.
      func f() {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(comment.briefSummary == nil)
    #expect(comment.bodyNodes.isEmpty)
    #expect(comment.parameterLayout == nil)
    #expect(comment.parameters.isEmpty)
    #expect(comment.returns == nil)

    let throwsField = try #require(comment.throws)
    #expect(
      throwsField.debugDescription()
        == """
        Paragraph
        └─ Text " An error."
        """
    )
  }

  @Test func unrecognizedFieldsGoIntoBodyNodes() throws {
    let decl: DeclSyntax = """
      /// - Blahblah: Blah.
      /// - Return: A value.
      /// - Throw: An error.
      func f() {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(comment.briefSummary == nil)
    #expect(
      comment.bodyNodes.map { $0.debugDescription() }
        == [
          """
          UnorderedList
          ├─ ListItem
          │  └─ Paragraph
          │     └─ Text "Blahblah: Blah."
          ├─ ListItem
          │  └─ Paragraph
          │     └─ Text "Return: A value."
          └─ ListItem
             └─ Paragraph
                └─ Text "Throw: An error."
          """
        ]
    )
    #expect(comment.parameterLayout == nil)
    #expect(comment.parameters.isEmpty)
    #expect(comment.returns == nil)
    #expect(comment.throws == nil)
  }

  @Test func nestedCommentInParameter() throws {
    let decl: DeclSyntax = """
      /// - Parameters:
      ///   - g: A function.
      ///     - Parameter x: A value.
      ///     - Parameter y: Another value.
      ///     - Returns: A result.
      func f(g: (x: Int, y: Int) -> Int) {}
      """
    let comment = try #require(DocumentationComment(extractedFrom: decl))
    #expect(comment.briefSummary == nil)
    #expect(comment.bodyNodes.isEmpty)
    #expect(comment.parameterLayout == .outline)
    #expect(comment.parameters.count == 1)
    #expect(comment.parameters[0].name == "g")
    #expect(comment.returns == nil)
    #expect(comment.throws == nil)

    let paramComment = comment.parameters[0].comment
    #expect(
      paramComment.briefSummary?.debugDescription()
        == """
        Paragraph
        └─ Text " A function."
        """
    )
    #expect(paramComment.bodyNodes.isEmpty)
    #expect(paramComment.parameterLayout == .separated)
    #expect(paramComment.parameters.count == 2)
    #expect(paramComment.parameters[0].name == "x")
    #expect(
      paramComment.parameters[0].comment.briefSummary?.debugDescription()
        == """
        Paragraph
        └─ Text " A value."
        """
    )
    #expect(paramComment.parameters[1].name == "y")
    #expect(
      paramComment.parameters[1].comment.briefSummary?.debugDescription()
        == """
        Paragraph
        └─ Text " Another value."
        """
    )
    #expect(
      paramComment.returns?.debugDescription()
        == """
        Paragraph
        └─ Text " A result."
        """
    )
    #expect(paramComment.throws == nil)
  }
}
