// sm:disable file_header
//
// Adapted from swift-format's ValidateDocumentationComments.swift
//
// https://github.com/apple/swift-format
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Foundation
import SwiftiomaticSyntax

struct ValidateDocumentationCommentsRule {
  static let id = "validate_documentation_comments"
  static let name = "Validate Documentation Comments"
  static let summary =
    "Documentation comments must have matching parameter names, returns clauses, and throws clauses."
  static let isOptIn = true
  var options = SeverityOption<Self>(.warning)
}

extension ValidateDocumentationCommentsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

// MARK: - Doc Comment Parsing

/// Parsed doc comment structure extracted from trivia.
private struct ParsedDocComment {
  var parameters: [String] = []
  var hasReturns = false
  var hasThrows = false
  /// Whether the parameter section uses the plural `Parameters:` outline form.
  var usesPluralParameters = false
  /// Whether the parameter section uses the singular `Parameter name:` form.
  var usesSingularParameter = false
}

/// Extracts doc comment lines from leading trivia and parses them.
private func parseDocComment(from trivia: Trivia) -> ParsedDocComment? {
  var lines: [String] = []

  for piece in trivia {
    switch piece {
    case .docLineComment(let text):
      // Strip `/// ` or `///` prefix
      let line = text.hasPrefix("/// ") ? String(text.dropFirst(4)) : String(text.dropFirst(3))
      lines.append(line)
    case .docBlockComment(let text):
      // Strip `/** ` and ` */`
      let stripped = text.dropFirst(3).dropLast(2)
      for line in stripped.split(separator: "\n", omittingEmptySubsequences: false) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let cleaned =
          if trimmed.hasPrefix("* ") {
            String(trimmed.dropFirst(2))
          } else if trimmed == "*" {
            ""
          } else {
            trimmed
          }
        lines.append(cleaned)
      }
    default:
      break
    }
  }

  guard !lines.isEmpty else { return nil }

  var result = ParsedDocComment()

  for line in lines {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    let lowered = trimmed.lowercased()

    // `- Parameter name: description`
    if lowered.hasPrefix("- parameter ") {
      let afterPrefix = trimmed.dropFirst("- Parameter ".count)
      if let colonIndex = afterPrefix.firstIndex(of: ":") {
        let name = String(afterPrefix[afterPrefix.startIndex..<colonIndex])
          .trimmingCharacters(in: .whitespaces)
        result.parameters.append(name)
        result.usesSingularParameter = true
      }
    }
    // `- Parameters:` (plural outline form)
    else if lowered.hasPrefix("- parameters:") {
      result.usesPluralParameters = true
    }
    // `  - name: description` (nested under Parameters:)
    else if result.usesPluralParameters && trimmed.hasPrefix("- ") {
      let afterDash = trimmed.dropFirst(2)
      if let colonIndex = afterDash.firstIndex(of: ":") {
        let name = String(afterDash[afterDash.startIndex..<colonIndex])
          .trimmingCharacters(in: .whitespaces)
        // Skip known non-parameter tags that might appear after parameters
        let lowerName = name.lowercased()
        if lowerName != "returns" && lowerName != "throws" {
          result.parameters.append(name)
        }
        if lowerName == "returns" { result.hasReturns = true }
        if lowerName == "throws" { result.hasThrows = true }
      }
    }
    // `- Returns: description`
    else if lowered.hasPrefix("- returns:") {
      result.hasReturns = true
    }
    // `- Throws: description`
    else if lowered.hasPrefix("- throws:") {
      result.hasThrows = true
    }
  }

  return result
}

// MARK: - Visitor

extension ValidateDocumentationCommentsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      checkFunctionLike(
        DeclSyntax(node),
        name: node.name.text,
        parameters: node.signature.parameterClause.parameters,
        returnClause: node.signature.returnClause,
        throwsClause: node.signature.effectSpecifiers?.throwsClause
      )
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      checkFunctionLike(
        DeclSyntax(node),
        name: "init",
        parameters: node.signature.parameterClause.parameters,
        returnClause: nil,
        throwsClause: node.signature.effectSpecifiers?.throwsClause
      )
    }

    private func checkFunctionLike(
      _ node: DeclSyntax,
      name: String,
      parameters: FunctionParameterListSyntax,
      returnClause: ReturnClauseSyntax?,
      throwsClause: ThrowsClauseSyntax?
    ) {
      guard let doc = parseDocComment(from: node.leadingTrivia) else { return }

      // If there are no parameter docs, returns, or throws — it's a summary-only
      // doc comment. That's fine.
      guard !doc.parameters.isEmpty || doc.hasReturns || doc.hasThrows else { return }

      let funcParamNames = parameters.map { ($0.secondName ?? $0.firstName).text }

      // Validate parameter layout style
      if doc.usesPluralParameters && funcParamNames.count == 1 {
        violations.append(
          .init(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "Use singular '- Parameter \(funcParamNames[0]):' instead of '- Parameters:' for a single parameter"
          )
        )
        // Don't check param names when the layout is wrong
        return
      }
      if doc.usesSingularParameter && funcParamNames.count > 1 {
        violations.append(
          .init(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "Use '- Parameters:' with nested items instead of separate '- Parameter' entries for multiple parameters"
          )
        )
        return
      }

      // Validate parameter names match
      if doc.parameters.count != funcParamNames.count
        || !zip(doc.parameters, funcParamNames).allSatisfy({ $0 == $1 })
      {
        violations.append(
          .init(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "Documentation parameters of '\(name)' don't match its function signature"
          )
        )
      }

      // Validate returns
      let returnsNonVoid: Bool =
        if let returnClause {
          returnClause.type.trimmedDescription != "Void"
            && returnClause.type.trimmedDescription != "Never"
        } else {
          false
        }

      if returnClause == nil && doc.hasReturns {
        violations.append(
          .init(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Remove 'Returns:' from '\(name)'; it does not return a value"
          )
        )
      } else if returnsNonVoid && !doc.hasReturns {
        violations.append(
          .init(
            position: returnClause!.positionAfterSkippingLeadingTrivia,
            reason: "Add a 'Returns:' section to document the return value of '\(name)'"
          )
        )
      }

      // Validate throws
      let isThrows = throwsClause?.throwsSpecifier.tokenKind == .keyword(.throws)
      if throwsClause == nil && doc.hasThrows {
        violations.append(
          .init(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Remove 'Throws:' from '\(name)'; it does not throw any errors"
          )
        )
      } else if isThrows && !doc.hasThrows {
        violations.append(
          .init(
            position: throwsClause!.positionAfterSkippingLeadingTrivia,
            reason: "Add a 'Throws:' section to document the errors thrown by '\(name)'"
          )
        )
      }
    }
  }
}
