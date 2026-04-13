// sm:disable file_header
//
// Adapted from swift-format's OneCasePerLine.swift
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

struct OneCasePerLineRule {
  static let id = "one_case_per_line"
  static let name = "One Case Per Line"
  static let summary =
    "Enum cases with associated values or raw values should each appear in their own `case` declaration."
  static let isCorrectable = true
  var options = SeverityOption<Self>(.warning)
}

extension OneCasePerLineRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension OneCasePerLineRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumCaseDeclSyntax) {
      guard node.elements.count > 1 else { return }

      for element in node.elements {
        guard element.parameterClause != nil || element.rawValue != nil else {
          continue
        }
        violations.append(
          .init(
            position: element.name.positionAfterSkippingLeadingTrivia,
            reason: "Move '\(element.name.text)' to its own 'case' declaration"
          )
        )
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
      var newMembers: [MemberBlockItemSyntax] = []
      var didRewrite = false

      for member in node.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
          caseDecl.elements.count > 1,
          caseDecl.elements.contains(where: {
            $0.parameterClause != nil || $0.rawValue != nil
          }),
          !isDisabled(atStartPositionOf: caseDecl)
        else {
          newMembers.append(member)
          continue
        }

        didRewrite = true
        numberOfCorrections += 1

        // Split into groups: plain elements are collected together, elements with
        // associated/raw values get their own case declaration.
        var plainElements: [EnumCaseElementSyntax] = []
        var isFirst = true

        for element in caseDecl.elements {
          if element.parameterClause != nil || element.rawValue != nil {
            // Flush any accumulated plain elements first
            if !plainElements.isEmpty {
              let caseDeclCopy = makeCaseDecl(
                basis: caseDecl, elements: plainElements, member: member,
                preserveLeadingTrivia: isFirst
              )
              newMembers.append(caseDeclCopy)
              isFirst = false
              plainElements.removeAll()
            }

            // Emit this element as its own case declaration
            var singleElement = element
            singleElement.trailingComma = nil
            let caseDeclCopy = makeCaseDecl(
              basis: caseDecl, elements: [singleElement], member: member,
              preserveLeadingTrivia: isFirst
            )
            newMembers.append(caseDeclCopy)
            isFirst = false
          } else {
            plainElements.append(element)
          }
        }

        // Flush remaining plain elements
        if !plainElements.isEmpty {
          let caseDeclCopy = makeCaseDecl(
            basis: caseDecl, elements: plainElements, member: member,
            preserveLeadingTrivia: isFirst
          )
          newMembers.append(caseDeclCopy)
        }
      }

      guard didRewrite else { return super.visit(node) }

      var newEnum = node
      newEnum.memberBlock.members = MemberBlockItemListSyntax(newMembers)
      return super.visit(DeclSyntax(newEnum).cast(EnumDeclSyntax.self))
    }

    /// Creates a new case declaration from the basis, using the given elements.
    private func makeCaseDecl(
      basis: EnumCaseDeclSyntax,
      elements: [EnumCaseElementSyntax],
      member: MemberBlockItemSyntax,
      preserveLeadingTrivia: Bool
    ) -> MemberBlockItemSyntax {
      var newCaseDecl = basis
      // Remove trailing comma from the last element
      var fixedElements = elements
      fixedElements[fixedElements.count - 1].trailingComma = nil
      newCaseDecl.elements = EnumCaseElementListSyntax(fixedElements)

      if !preserveLeadingTrivia {
        newCaseDecl.leadingTrivia = .newline
      }

      var newMember = member
      newMember.decl = DeclSyntax(newCaseDecl)
      return newMember
    }
  }
}
