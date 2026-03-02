import SwiftSyntax

struct FileLengthRule {
  var options = FileLengthOptions()

  static let configuration = FileLengthConfiguration()
}

extension FileLengthRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FileLengthRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SourceFileSyntax) {
      let lineCount =
        configuration.ignoreCommentOnlyLines
        ? CommentLinesVisitor(locationConverter: locationConverter)
          .walk(tree: node, handler: \.linesWithCode).count
        : file.lines.count

      let severity: Severity
      let upperBound: Int
      if let error = configuration.severityConfiguration.error, lineCount > error {
        severity = .error
        upperBound = error
      } else if lineCount > configuration.severityConfiguration.warning {
        severity = .warning
        upperBound = configuration.severityConfiguration.warning
      } else {
        return
      }

      let reason =
        "File should contain \(upperBound) lines or less"
        + (configuration
          .ignoreCommentOnlyLines ? " excluding comments and whitespaces" : "")
        + ": currently contains \(lineCount)"

      // Position violation at the start of the last line to avoid boundary issues
      let lastLine = file.lines.last
      let lastLineStartOffset = lastLine?.byteRange.location ?? 0
      let violationPosition = AbsolutePosition(utf8Offset: lastLineStartOffset.value)

      let violation = SyntaxViolation(
        position: violationPosition,
        reason: reason,
        severity: severity,
      )
      violations.append(violation)
    }
  }
}
