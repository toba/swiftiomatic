import SwiftiomaticKit
import XcodeKit

final class LintFileCommand: NSObject, XCSourceEditorCommand {
  func perform(
    with invocation: XCSourceEditorCommandInvocation,
    completionHandler: @escaping (Error?) -> Void
  ) {
    let buffer = invocation.buffer

    guard buffer.isSwiftSource else {
      completionHandler(FormatCommandError.unsupportedContentType(buffer.contentUTI))
      return
    }

    let source = buffer.completeBuffer
    let diagnostics = Swiftiomatic.lint(source)

    guard !diagnostics.isEmpty else {
      completionHandler(nil)
      return
    }

    let summary = diagnostics.map { diagnostic in
      "Line \(diagnostic.line): [\(diagnostic.severity.rawValue)] \(diagnostic.message) (\(diagnostic.ruleID))"
    }.joined(separator: "\n")

    completionHandler(FormatCommandError.lintSummary(count: diagnostics.count, summary: summary))
  }
}
