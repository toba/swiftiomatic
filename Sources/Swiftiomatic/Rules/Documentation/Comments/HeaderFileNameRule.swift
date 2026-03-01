import Foundation
import SwiftSyntax

struct HeaderFileNameRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = HeaderFileNameConfiguration()

  static let description = RuleDescription(
    identifier: "header_file_name",
    name: "Header File Name",
    description: "File name in header comment should match the actual file name",
    scope: .lint,
    nonTriggeringExamples: [
      Example(
        """
        // Correct.swift
        struct Foo {}
        """,
        configuration: ["file_name": "Correct.swift"],
      )
    ],
    triggeringExamples: [
      Example(
        """
        ↓// Wrong.swift
        struct Foo {}
        """,
        configuration: ["file_name": "Correct.swift"],
      )
    ],
  )
}

extension HeaderFileNameRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension HeaderFileNameRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SourceFileSyntax) {
      guard let fileName = file.path?.components(separatedBy: "/").last,
        fileName.hasSuffix(".swift")
      else { return }

      // Check first few trivia pieces for file name reference
      let trivia = node.leadingTrivia
      var offset = node.position
      for piece in trivia {
        if case .lineComment(let comment) = piece {
          let trimmed = comment.dropFirst(2).trimmingCharacters(in: .whitespaces)
          if trimmed.hasSuffix(".swift"), trimmed != fileName,
            !trimmed.contains(" "), !trimmed.contains("/")
          {
            violations.append(offset)
            return
          }
        }
        offset = offset.advanced(by: piece.sourceLength.utf8Length)
      }
    }
  }
}
