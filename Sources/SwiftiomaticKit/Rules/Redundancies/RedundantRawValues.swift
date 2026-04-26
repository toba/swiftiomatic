//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Remove raw values that match the enum case name for `String`-backed enums.
///
/// When a `String` enum case's raw value is identical to its name (e.g. `case foo = "foo"`),
/// the raw value is redundant because Swift automatically assigns the case name as the raw value.
///
/// Lint: If a redundant raw value is found, a lint warning is raised.
///
/// Rewrite: The redundant raw value initializer is removed.
final class RedundantRawValues: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
    // Only applies inside String-backed enums.
    guard isInsideStringEnum(node) else {
      return DeclSyntax(node)
    }

    var elements = node.elements
    var didChange = false

    for (index, element) in elements.enumerated() {
      guard let rawValue = element.rawValue,
        let stringLiteral = rawValue.value.as(StringLiteralExprSyntax.self),
        isSimpleStringLiteral(stringLiteral, matching: element.name.text)
      else {
        continue
      }

      diagnose(.removeRedundantRawValue(name: element.name.text), on: rawValue)

      var newElement = element
      newElement.rawValue = nil
      // Clean up trailing trivia on the name token (space before `=` is no longer needed).
      newElement.name.trailingTrivia = rawValue.value.trailingTrivia

      elements = elements.with(
        \.[elements.index(elements.startIndex, offsetBy: index)],
        newElement
      )
      didChange = true
    }

    guard didChange else { return DeclSyntax(node) }

    var newNode = node
    newNode.elements = elements
    return DeclSyntax(newNode)
  }

  /// Returns `true` if the given node is inside an enum with `String` raw type.
  private func isInsideStringEnum(_ node: some SyntaxProtocol) -> Bool {
    var current = node.parent
    while let parent = current {
      if let enumDecl = parent.as(EnumDeclSyntax.self) {
        return hasStringRawType(enumDecl)
      }
      current = parent.parent
    }
    return false
  }

  /// Returns `true` if the enum declares `: String` in its inheritance clause.
  private func hasStringRawType(_ enumDecl: EnumDeclSyntax) -> Bool {
    guard let inheritanceClause = enumDecl.inheritanceClause else { return false }
    return inheritanceClause.inheritedTypes.contains { inherited in
      inherited.type.trimmedDescription == "String"
    }
  }

  /// Returns `true` if the string literal is a simple (non-interpolated) string matching the text.
  private func isSimpleStringLiteral(_ literal: StringLiteralExprSyntax, matching text: String) -> Bool {
    // Must be a simple string with exactly one segment and no interpolation.
    guard literal.segments.count == 1,
      let segment = literal.segments.first?.as(StringSegmentSyntax.self)
    else {
      return false
    }
    return segment.content.text == text
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantRawValue(name: String) -> Finding.Message {
    "remove redundant raw value for '\(name)'; it matches the case name"
  }
}
