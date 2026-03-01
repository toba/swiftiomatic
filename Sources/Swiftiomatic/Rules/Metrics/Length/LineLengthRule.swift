import Foundation
import SwiftSyntax

struct LineLengthRule {
  var options = LineLengthOptions()

  static let configuration = LineLengthConfiguration()

  static let description = RuleDescription(
    identifier: "line_length",
    name: "Line Length",
    description: "Lines should not span too many characters.",
    nonTriggeringExamples: [
      Example(String(repeating: "/", count: 120) + ""),
      Example(
        String(
          repeating:
            "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
          count: 120,
        ) + "",
      ),
      Example(String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 120) + ""),
    ],
    triggeringExamples: [
      Example(String(repeating: "/", count: 121) + ""),
      Example(
        String(
          repeating:
            "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
          count: 121,
        ) + "",
      ),
      Example(String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 121) + ""),
    ].skipWrappingInCommentTests().skipWrappingInStringTests(),
  )
}

extension LineLengthRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LineLengthRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    // To store line numbers that should be ignored based on configuration
    private var functionDeclarationLines = Set<Int>()
    private var commentOnlyLines = Set<Int>()
    private var interpolatedStringLines = Set<Int>()
    private var multilineStringLines = Set<Int>()
    private var regexLiteralLines = Set<Int>()

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
      // Populate functionDeclarationLines if ignores_function_declarations is true
      if configuration.ignoresFunctionDeclarations {
        let funcVisitor = FunctionLineVisitor(locationConverter: locationConverter)
        functionDeclarationLines = funcVisitor.walk(tree: node, handler: \.lines)
      }

      // Populate multilineStringLines if ignores_multiline_strings is true
      if configuration.ignoresMultilineStrings {
        let stringVisitor =
          MultilineStringLiteralVisitor(locationConverter: locationConverter)
        multilineStringLines = stringVisitor.walk(tree: node, handler: \.linesSpanned)
      }

      // Populate interpolatedStringLines if ignores_interpolated_strings is true
      if configuration.ignoresInterpolatedStrings {
        let interpVisitor =
          InterpolatedStringLineVisitor(locationConverter: locationConverter)
        interpolatedStringLines = interpVisitor.walk(tree: node, handler: \.lines)
      }

      // Populate commentOnlyLines if ignores_comments is true
      if configuration.ignoresComments {
        let commentVisitor = CommentLinesVisitor(locationConverter: locationConverter)
        commentOnlyLines = commentVisitor.walk(tree: node, handler: \.commentOnlyLines)
      }

      // Populate regexLiteralLines if ignores_regex_literals is true
      if configuration.ignoresRegexLiterals {
        let regexVisitor = RegexLiteralVisitor(locationConverter: locationConverter)
        regexLiteralLines = regexVisitor.walk(tree: node, handler: \.lines)
      }

      return .skipChildren  // We'll do the main processing in visitPost
    }

    override func visitPost(_: SourceFileSyntax) {
      let minLengthThreshold = configuration.params.map(\.value).min() ?? .max

      for line in file.lines {
        // Quick check to skip very short lines before expensive stripping
        // `line.content.count` <= `line.range.length` is true.
        // So, check `line.range.length` is larger than minimum parameter value
        // for avoiding using heavy `line.content.count`.
        if line.range.length < minLengthThreshold {
          continue
        }

        // Apply ignore configurations
        if configuration.ignoresFunctionDeclarations,
          functionDeclarationLines.contains(line.index)
        {
          continue
        }
        if configuration.ignoresComments, commentOnlyLines.contains(line.index) {
          continue
        }
        if configuration.ignoresInterpolatedStrings,
          interpolatedStringLines.contains(line.index)
        {
          continue
        }
        if configuration.ignoresMultilineStrings,
          multilineStringLines.contains(line.index)
        {
          continue
        }
        if configuration.ignoresRegexLiterals, regexLiteralLines.contains(line.index) {
          continue
        }
        if configuration.excludedLinesPatterns.contains(where: {
          regex($0).firstMatch(in: line.content, range: line.content.fullNSRange) != nil
        }) {
          continue
        }

        // String stripping logic
        var strippedString = line.content
        if configuration.ignoresURLs {
          strippedString = strippedString.strippingURLs
        }
        strippedString = stripLiterals(
          fromSourceString: strippedString, withDelimiter: "#colorLiteral",
        )
        strippedString = stripLiterals(
          fromSourceString: strippedString, withDelimiter: "#imageLiteral",
        )

        let length = strippedString.count  // Character count for reporting

        // Check against configured length limits
        for param in configuration.params where length > param.value {
          let reason =
            "Line should be \(param.value) characters or less; "
            + "currently it has \(length) characters"
          // Position the violation at the start of the line, consistent with original behavior
          violations.append(
            SyntaxViolation(
              position:
                locationConverter
                .position(ofLine: line.index, column: 1),  // Start of the line
              reason: reason,
              severity: param.severity,
            ),
          )
          break  // Only report one violation (the most severe one reached) per line
        }
      }
    }

    /// Strip color and image literals from the source string
    private func stripLiterals(
      fromSourceString sourceString: String,
      withDelimiter delimiter: String,
    ) -> String {
      var modifiedString = sourceString
      while modifiedString.contains("\(delimiter)(") {
        if let rangeStart = modifiedString.range(of: "\(delimiter)("),
          let rangeEnd = modifiedString.range(
            of: ")", options: .literal,
            range: rangeStart.lowerBound..<modifiedString.endIndex,
          )
        {
          modifiedString.replaceSubrange(
            rangeStart.lowerBound..<rangeEnd.upperBound,
            with: "#",
          )
        } else {
          break
        }
      }
      return modifiedString
    }
  }
}

// MARK: - Helper Visitors for Pre-computation

private class LineCollectingVisitor: SyntaxVisitor {
  let locationConverter: SourceLocationConverter
  var lines = Set<Int>()

  init(locationConverter: SourceLocationConverter) {
    self.locationConverter = locationConverter
    super.init(viewMode: .sourceAccurate)
  }

  func collectLines(from startPosition: AbsolutePosition, to endPosition: AbsolutePosition) {
    let startLine = locationConverter.location(for: startPosition).line
    let endLine = locationConverter.location(for: endPosition).line
    for line in startLine...endLine {
      lines.insert(line)
    }
  }
}

private final class FunctionLineVisitor: LineCollectingVisitor {
  override func visitPost(_ node: FunctionDeclSyntax) {
    collectLines(
      from: node.positionAfterSkippingLeadingTrivia,
      to: node.genericWhereClause?.endPositionBeforeTrailingTrivia
        ?? node.signature.endPositionBeforeTrailingTrivia,
    )
  }

  override func visitPost(_ node: InitializerDeclSyntax) {
    collectLines(
      from: node.positionAfterSkippingLeadingTrivia,
      to: node.genericWhereClause?.endPositionBeforeTrailingTrivia
        ?? node.signature.endPositionBeforeTrailingTrivia,
    )
  }

  override func visitPost(_ node: SubscriptDeclSyntax) {
    collectLines(
      from: node.positionAfterSkippingLeadingTrivia,
      to: node.genericWhereClause?.endPositionBeforeTrailingTrivia
        ?? node.returnClause.endPositionBeforeTrailingTrivia,
    )
  }
}

private final class InterpolatedStringLineVisitor: LineCollectingVisitor {
  override func visitPost(_ node: ExpressionSegmentSyntax) {
    collectLines(
      from: node.positionAfterSkippingLeadingTrivia,
      to: node.endPositionBeforeTrailingTrivia,
    )
  }
}

private final class RegexLiteralVisitor: LineCollectingVisitor {
  override func visitPost(_ node: RegexLiteralExprSyntax) {
    collectLines(
      from: node.positionAfterSkippingLeadingTrivia,
      to: node.endPositionBeforeTrailingTrivia,
    )
  }
}

private let urlDetector: NSDataDetector? = {
  try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
}()

extension String {
  fileprivate var strippingURLs: String {
    guard let urlDetector else { return self }
    return urlDetector.stringByReplacingMatches(
      in: self, options: [], range: fullNSRange, withTemplate: "",
    )
  }
}
