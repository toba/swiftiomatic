import Foundation
package import SwiftSyntax

// MARK: - CommandVisitor

/// Visits the syntax tree to collect all `sm:` inline comment commands
///
/// Scans both leading and trailing trivia on every token for line comments
/// containing the `sm:` prefix (e.g. `// sm:disable:next rule_id`).
package final class CommandVisitor: SyntaxVisitor {
  /// The collected ``Command`` values found during traversal
  package private(set) var commands: [Command] = []

  /// The location converter for mapping byte positions to line/column numbers
  package let locationConverter: SourceLocationConverter

  /// Creates a visitor with the given location converter
  ///
  /// - Parameters:
  ///   - locationConverter: Converter for mapping absolute positions to source locations.
  package init(locationConverter: SourceLocationConverter) {
    self.locationConverter = locationConverter
    super.init(viewMode: .sourceAccurate)
  }

  package override func visitPost(_ node: TokenSyntax) {
    collectCommands(in: node.leadingTrivia, offset: node.position)
    collectCommands(in: node.trailingTrivia, offset: node.endPositionBeforeTrailingTrivia)
  }

  private func collectCommands(in trivia: Trivia, offset: AbsolutePosition) {
    var position = offset
    for piece in trivia {
      switch piece {
      case .lineComment(let comment):
        guard
          let lower = comment.range(of: "sm:")?.lowerBound
            .samePosition(in: comment.utf8)
        else {
          break
        }
        let offset = comment.utf8.distance(from: comment.utf8.startIndex, to: lower)
        let location = locationConverter.location(for: position.advanced(by: offset))
        let line = locationConverter.sourceLines[location.line - 1]
        guard let character = line.characterPosition(of: location.column) else {
          break
        }
        let command = Command(
          commandString: String(comment[lower...]),
          line: location.line,
          range: character..<(character + piece.sourceLength.utf8Length - offset),
        )
        commands.append(command)
      default:
        break
      }
      position += piece.sourceLength
    }
  }
}
