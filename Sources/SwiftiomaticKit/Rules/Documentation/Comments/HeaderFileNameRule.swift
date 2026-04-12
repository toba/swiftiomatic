import Foundation
import SwiftiomaticSyntax

struct HeaderFileNameRule {
  static let id = "header_file_name"
  static let name = "Header File Name"
  static let summary = "File name in header comment should match the actual file name"
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        // Correct.swift
        struct Foo {}
        """,
        configuration: ["file_name": "Correct.swift"],
      )
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓// Wrong.swift
        struct Foo {}
        """,
        configuration: ["file_name": "Correct.swift"],
      )
    ]
  }

  static let requiresFileOnDisk = true

  var options = SeverityOption<Self>(.warning)
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
