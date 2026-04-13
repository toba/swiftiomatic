// sm:disable file_header
//
// Adapted from swift-format's FullyIndirectEnum.swift
//
// https://github.com/apple/swift-format
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import SwiftiomaticSyntax

struct FullyIndirectEnumRule {
  static let id = "fully_indirect_enum"
  static let name = "Fully Indirect Enum"
  static let summary =
    "When all cases of an enum are `indirect`, the enum itself should be declared `indirect`."
  static let isCorrectable = true
  var options = SeverityOption<Self>(.warning)
}

extension FullyIndirectEnumRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension FullyIndirectEnumRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumDeclSyntax) {
      guard !node.modifiers.contains(keyword: .indirect),
        allCasesAreIndirect(in: node.memberBlock.members)
      else {
        return
      }
      violations.append(
        .init(
          position: node.enumKeyword.positionAfterSkippingLeadingTrivia,
          reason:
            "Declare enum '\(node.name.text)' itself as 'indirect' instead of marking every case",
        )
      )
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
      guard !node.modifiers.contains(keyword: .indirect),
        allCasesAreIndirect(in: node.memberBlock.members)
      else {
        return super.visit(node)
      }
      guard !isDisabled(atStartPositionOf: node) else {
        return super.visit(node)
      }

      numberOfCorrections += 1

      // Remove `indirect` from each case
      let newMembers = node.memberBlock.members.map { member -> MemberBlockItemSyntax in
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
          caseDecl.modifiers.contains(keyword: .indirect)
        else {
          return member
        }
        var newCase = caseDecl
        let indirectTrivia = caseDecl.modifiers.first {
          $0.name.tokenKind == .keyword(.indirect)
        }?.leadingTrivia

        newCase.modifiers = newCase.modifiers.filter {
          $0.name.tokenKind != .keyword(.indirect)
        }

        // Transfer leading trivia from the removed `indirect` modifier
        if let trivia = indirectTrivia {
          if let firstModifier = newCase.modifiers.first {
            var updated = firstModifier
            updated.leadingTrivia = trivia
            newCase.modifiers = DeclModifierListSyntax(
              [updated] + Array(newCase.modifiers.dropFirst())
            )
          } else {
            newCase.caseKeyword.leadingTrivia = trivia
          }
        }

        var newMember = member
        newMember.decl = DeclSyntax(newCase)
        return newMember
      }

      // Add `indirect` to the enum declaration
      var newEnum = node

      // Build the new `indirect` modifier, transferring leading trivia from the
      // first existing token so formatting (indentation, comments) is preserved.
      let firstToken = node.firstToken(viewMode: .sourceAccurate)
      let leadingTrivia: Trivia
      if firstToken?.tokenKind == .keyword(.enum) {
        leadingTrivia = firstToken?.leadingTrivia ?? []
        newEnum.enumKeyword.leadingTrivia = []
      } else {
        leadingTrivia = []
      }

      let indirectModifier = DeclModifierSyntax(
        leadingTrivia: leadingTrivia,
        name: .keyword(.indirect),
        trailingTrivia: .space
      )

      newEnum.modifiers = DeclModifierListSyntax(
        Array(newEnum.modifiers) + [indirectModifier]
      )
      newEnum.memberBlock.members = MemberBlockItemListSyntax(newMembers)

      return super.visit(DeclSyntax(newEnum).cast(EnumDeclSyntax.self))
    }
  }
}

/// Whether the enum has at least one case and every case is marked `indirect`.
private func allCasesAreIndirect(in members: MemberBlockItemListSyntax) -> Bool {
  var hasCases = false
  for member in members {
    if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
      hasCases = true
      guard caseDecl.modifiers.contains(keyword: .indirect) else {
        return false
      }
    }
  }
  return hasCases
}
