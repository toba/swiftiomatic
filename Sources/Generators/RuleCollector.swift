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

import Foundation
import SwiftiomaticCore
import SwiftParser
import SwiftSyntax

/// Collects information about rules in the formatter code base.
package final class RuleCollector {
  /// Information about a detected rule.
  struct DetectedRule: Hashable {
    /// The type name of the rule.
    let typeName: String

    /// The custom name from `static let name = "..."`, or `nil` to use `typeName`.
    let customName: String?

    /// The description of the rule, extracted from the rule class or struct DocC comment
    /// with `DocumentationCommentText(extractedFrom:)`
    let description: String?

    /// The syntax node types visited by the rule type.
    let visitedNodes: [String]

    /// Indicates whether the rule can format code (all rules can lint).
    let canFormat: Bool

    /// Indicates whether the rule is disabled by default, i.e. requires opting in to use it.
    let isOptIn: Bool

    /// The config group this rule belongs to, or `nil` if ungrouped.
    let group: ConfigGroup?

    /// The name to use for this rule (custom name if set, otherwise type name).
    var ruleName: String { customName ?? typeName }
  }

  /// A list of all rules that can lint (thus also including format rules) found in the code base.
  var allLinters = Set<DetectedRule>()

  /// A list of all the format-only rules found in the code base.
  var allFormatters = Set<DetectedRule>()

  /// A dictionary mapping syntax node types to the lint/format rules that visit them.
  var syntaxNodeLinters = [String: [String]]()

  package init() {}

  /// Populates the internal collections with rules in the given directory.
  ///
  /// - Parameter url: The file system URL that should be scanned for rules.
  package func collect(from url: URL) throws {
    // For each file in the Rules directory, find types that either conform to SyntaxLintRule or
    // inherit from SyntaxFormatRule.
    let fm = FileManager.default
    guard let rulesEnumerator = fm.enumerator(atPath: url.path) else {
      fatalError("Could not list the directory \(url.path)")
    }

    for baseName in rulesEnumerator {
      // Ignore files that aren't Swift source files.
      guard let baseName = baseName as? String, baseName.hasSuffix(".swift") else { continue }

      let fileURL = url.appendingPathComponent(baseName)
      let fileInput = try String(contentsOf: fileURL, encoding: .utf8)
      let sourceFile = Parser.parse(source: fileInput)

      for statement in sourceFile.statements {
        guard let detectedRule = self.detectedRule(at: statement) else { continue }

        if detectedRule.canFormat {
          // Format rules just get added to their own list; we run them each over the entire tree in
          // succession.
          allFormatters.insert(detectedRule)
        }

        // Lint rules (this includes format rules, which can also lint) get added to a mapping over
        // the names of the types they touch so that they can be interleaved into one pass over the
        // tree.
        allLinters.insert(detectedRule)
        for visitedNode in detectedRule.visitedNodes {
          syntaxNodeLinters[visitedNode, default: []].append(detectedRule.typeName)
        }
      }
    }
  }

  /// Determine the rule kind for the declaration in the given statement, if any.
  private func detectedRule(at statement: CodeBlockItemSyntax) -> DetectedRule? {
    let typeName: String
    let members: MemberBlockItemListSyntax
    let maybeInheritanceClause: InheritanceClauseSyntax?
    let description = DocumentationCommentText(extractedFrom: statement.item.leadingTrivia)

    if let classDecl = statement.item.as(ClassDeclSyntax.self) {
      typeName = classDecl.name.text
      members = classDecl.memberBlock.members
      maybeInheritanceClause = classDecl.inheritanceClause
    } else if let structDecl = statement.item.as(StructDeclSyntax.self) {
      typeName = structDecl.name.text
      members = structDecl.memberBlock.members
      maybeInheritanceClause = structDecl.inheritanceClause
    } else {
      return nil
    }

    // Make sure it has an inheritance clause.
    guard let inheritanceClause = maybeInheritanceClause else {
      return nil
    }

    // Scan through the inheritance clause to find one of the protocols/types we're interested in.
    for inheritance in inheritanceClause.inheritedTypes {
      guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self) else {
        continue
      }

      let canFormat: Bool
      switch identifier.name.text {
      case "SyntaxLintRule":
        canFormat = false
      case "SyntaxFormatRule":
        canFormat = true
      default:
        // Keep looking at the other inheritances.
        continue
      }

      // Now that we know it's a format or lint rule, collect the `visit` methods.
      var visitedNodes = [String]()
      for member in members {
        guard let function = member.decl.as(FunctionDeclSyntax.self) else { continue }
        guard function.name.text == "visit" else { continue }
        let params = function.signature.parameterClause.parameters
        guard let firstType = params.firstAndOnly?.type.as(IdentifierTypeSyntax.self) else {
          continue
        }
        visitedNodes.append(firstType.name.text)
      }

      /// Ignore it if it doesn't have any; there's no point in putting no-op rules in the pipeline.
      /// Otherwise, return it (we don't need to look at the rest of the inheritances).
      guard !visitedNodes.isEmpty else { return nil }
      return DetectedRule(
        typeName: typeName,
        customName: Self.extractCustomName(from: members),
        description: description?.text,
        visitedNodes: visitedNodes,
        canFormat: canFormat,
        isOptIn: Self.extractIsOptIn(from: members),
        group: Self.extractGroup(from: members)
      )
    }

    return nil
  }

  /// Extracts the custom `name` from `static let name = "..."` in the AST.
  /// Returns `nil` when no custom name override is present.
  private static func extractCustomName(from members: MemberBlockItemListSyntax) -> String? {
    for member in members {
      guard let varDecl = member.decl.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.firstAndOnly,
            let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
            pattern.identifier.text == "name"
      else { continue }

      if let initializer = binding.initializer?.value.as(StringLiteralExprSyntax.self),
         let segment = initializer.segments.firstAndOnly?.as(StringSegmentSyntax.self) {
        return segment.content.text
      }
    }
    return nil
  }

  /// Extracts `isOptIn` from `static let isOptIn = true` in the AST.
  /// Returns `false` (the base class default) when the override is absent.
  private static func extractIsOptIn(from members: MemberBlockItemListSyntax) -> Bool {
    for member in members {
      guard let varDecl = member.decl.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.firstAndOnly,
            let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
            pattern.identifier.text == "isOptIn"
      else { continue }

      // Stored property: `static let isOptIn = true`
      if let initializer = binding.initializer?.value.as(BooleanLiteralExprSyntax.self) {
        return initializer.literal.tokenKind == .keyword(.true)
      }

      // Computed property: `static var isOptIn: Bool { true }`
      if let accessorBlock = binding.accessorBlock,
         case .getter(let body) = accessorBlock.accessors {
        if let boolExpr = body.first?.item.as(BooleanLiteralExprSyntax.self) {
          return boolExpr.literal.tokenKind == .keyword(.true)
        }
        if let returnStmt = body.first?.item.as(ReturnStmtSyntax.self),
           let boolExpr = returnStmt.expression?.as(BooleanLiteralExprSyntax.self) {
          return boolExpr.literal.tokenKind == .keyword(.true)
        }
      }
    }
    return false
  }

  /// Extracts `group` from `static let group: ConfigGroup? = .someCase` in the AST.
  /// Returns `nil` (the base class default) when the override is absent.
  private static func extractGroup(from members: MemberBlockItemListSyntax) -> ConfigGroup? {
    for member in members {
      guard let varDecl = member.decl.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.firstAndOnly,
            let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
            pattern.identifier.text == "group"
      else { continue }

      let memberAccess: MemberAccessExprSyntax?

      // Stored property: `static let group: ConfigGroup? = .someCase`
      if let initializer = binding.initializer?.value.as(MemberAccessExprSyntax.self) {
        memberAccess = initializer
      }
      // Computed property: `static var group: ConfigGroup? { .someCase }`
      else if let accessorBlock = binding.accessorBlock,
              case .getter(let body) = accessorBlock.accessors {
        if let expr = body.first?.item.as(MemberAccessExprSyntax.self) {
          memberAccess = expr
        } else if let returnStmt = body.first?.item.as(ReturnStmtSyntax.self) {
          memberAccess = returnStmt.expression?.as(MemberAccessExprSyntax.self)
        } else {
          memberAccess = nil
        }
      } else {
        memberAccess = nil
      }

      if let memberAccess {
        return ConfigGroup(rawValue: memberAccess.declName.baseName.text)
      }
    }
    return nil
  }
}
