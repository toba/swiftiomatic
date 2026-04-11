import SwiftSyntax

struct FileLengthRule {
  static let id = "file_length"
  static let name = "File Length"
  static let summary = "Files should not span too many lines."
  static var nonTriggeringExamples: [Example] {
    [
      Example(repeatElement("print(\"swiftlint\")\n", count: 399).joined())
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(repeatElement("print(\"swiftlint\")\n", count: 401).joined()),
      Example((repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined()),
      Example(repeatElement("print(\"swiftlint\")\n\n", count: 201).joined()),
    ]
  }

  var options = FileLengthOptions()
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
