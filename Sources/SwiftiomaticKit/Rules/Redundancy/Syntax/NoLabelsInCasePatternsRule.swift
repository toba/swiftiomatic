// sm:disable file_header
//
// Adapted from swift-format's NoLabelsInCasePatterns.swift
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

struct NoLabelsInCasePatternsRule {
  static let id = "no_labels_in_case_patterns"
  static let name = "No Labels In Case Patterns"
  static let summary =
    "Redundant labels in case patterns should be removed when the label matches the bound variable name."
  static let isCorrectable = true
  var options = SeverityOption<Self>(.warning)
}

extension NoLabelsInCasePatternsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoLabelsInCasePatternsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseLabelSyntax) {
      for item in node.caseItems {
        guard
          let exprPattern = item.pattern.as(ExpressionPatternSyntax.self),
          let funcCall = exprPattern.expression.as(FunctionCallExprSyntax.self)
        else {
          continue
        }

        for argument in funcCall.arguments {
          guard
            let label = argument.label,
            let patternExpr = argument.expression.as(PatternExprSyntax.self),
            let valueBinding = patternExpr.pattern.as(ValueBindingPatternSyntax.self)
          else {
            continue
          }

          let name = valueBinding.pattern.trimmedDescription
          guard name == label.text else { continue }

          // Remove `label: ` — from the label start through the colon and trailing space
          let correctionEnd =
            if let colon = argument.colon {
              colon.endPositionBeforeTrailingTrivia.advanced(
                by: colon.trailingTrivia.sourceLength.utf8Length
              )
            } else {
              label.endPositionBeforeTrailingTrivia
            }

          violations.append(
            .init(
              position: label.positionAfterSkippingLeadingTrivia,
              reason: "Remove redundant label '\(name)' from case pattern",
              correction: .init(
                start: label.positionAfterSkippingLeadingTrivia,
                end: correctionEnd,
                replacement: ""
              )
            )
          )
        }
      }
    }
  }
}
