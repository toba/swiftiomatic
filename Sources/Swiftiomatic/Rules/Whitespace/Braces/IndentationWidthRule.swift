import Foundation

struct IndentationWidthRule: Rule {
    static let id = "indentation_width"
    static let name = "Indentation Width"
    static let summary = "Indent code using either one tab or the configured amount of spaces, unindent to match previous indentations. Don't indent the first line."
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("firstLine\nsecondLine"),
              Example("firstLine\n    secondLine"),
              Example("firstLine\n\tsecondLine\n\t\tthirdLine\n\n\t\tfourthLine"),
              Example("firstLine\n\tsecondLine\n\t\tthirdLine\n\t//test\n\t\tfourthLine"),
              Example("firstLine\n    secondLine\n        thirdLine\nfourthLine"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("↓    firstLine", shouldTestMultiByteOffsets: false, shouldTestDisableCommand: false),
              Example("firstLine\n        secondLine"),
              Example("firstLine\n\tsecondLine\n\n↓\t\t\tfourthLine"),
              Example("firstLine\n    secondLine\n        thirdLine\n↓ fourthLine"),
            ]
    }
  // MARK: - Subtypes

  private enum Indentation: Equatable {
    case tabs(Int)
    case spaces(Int)

    func spacesEquivalent(indentationWidth: Int) -> Int {
      switch self {
      case .tabs(let tabs): return tabs * indentationWidth
      case .spaces(let spaces): return spaces
      }
    }
  }

  // MARK: - Properties

  var options = IndentationWidthOptions()

  // MARK: - Initializers

  // MARK: - Methods: Validation

  func validate(file: SwiftSource)
    -> [RuleViolation]
  {  // sm:disable:this function_body_length
    var violations: [RuleViolation] = []
    var previousLineIndentations: [Indentation] = []

    for line in file.lines {
      if ignoreCompilerDirective(line: line, in: file) { continue }

      // Skip line if it's a whitespace-only line
      let indentationCharacterCount = line.content.countOfLeadingCharacters(
        in: CharacterSet(charactersIn: " \t"),
      )
      if line.content.count == indentationCharacterCount { continue }

      if ignoreComment(line: line, in: file) || ignoreMultilineStrings(line: line, in: file) {
        continue
      }

      // Get space and tab count in prefix
      let prefix = String(line.content.prefix(indentationCharacterCount))
      let tabCount = prefix.count(where: { $0 == "\t" })
      let spaceCount = prefix.count(where: { $0 == " " })

      // Determine indentation
      let indentation: Indentation
      if tabCount != 0, spaceCount != 0 {
        // Catch mixed indentation
        violations.append(
          RuleViolation(
            ruleType: Self.self,
            severity: options.severityConfiguration.severity,
            location: Location(file: file, characterOffset: line.range.location),
            reason: "Code should be indented with tabs or "
              + "\(options.indentationWidth) spaces, but not both in the same line",
          ),
        )

        // Model this line's indentation using spaces (although it's tabs & spaces) to let parsing continue
        indentation = .spaces(spaceCount + tabCount * options.indentationWidth)
      } else if tabCount != 0 {
        indentation = .tabs(tabCount)
      } else {
        indentation = .spaces(spaceCount)
      }

      // Catch indented first line
      guard previousLineIndentations.isNotEmpty else {
        previousLineIndentations = [indentation]

        if indentation != .spaces(0) {
          // There's an indentation although this is the first line!
          violations.append(
            RuleViolation(
              ruleType: Self.self,
              severity: options.severityConfiguration.severity,
              location: Location(file: file, characterOffset: line.range.location),
              reason: "The first line shall not be indented",
            ),
          )
        }

        continue
      }

      let linesValidationResult = previousLineIndentations.map {
        validate(indentation: indentation, comparingTo: $0)
      }

      // Catch wrong indentation or wrong unindentation
      if !linesValidationResult.contains(true) {
        let isIndentation =
          previousLineIndentations.last.map {
            indentation
              .spacesEquivalent(indentationWidth: options.indentationWidth)
              >= $0.spacesEquivalent(indentationWidth: options.indentationWidth)
          } ?? true

        let indentWidth = options.indentationWidth
        violations.append(
          RuleViolation(
            ruleType: Self.self,
            severity: options.severityConfiguration.severity,
            location: Location(file: file, characterOffset: line.range.location),
            reason: isIndentation
              ? "Code should be indented using one tab or \(indentWidth) spaces"
              : "Code should be unindented by multiples of one tab or multiples of \(indentWidth) spaces",
          ),
        )
      }

      if linesValidationResult.first == true {
        // Reset previousLineIndentations to this line only
        // if this line's indentation matches the last valid line's indentation (first in the array)
        previousLineIndentations = [indentation]
      } else {
        // We not only store this line's indentation, but also keep what was stored before.
        // Therefore, the next line can be indented either according to the last valid line
        // or any of the succeeding, failing lines.
        // This mechanism avoids duplicate warnings.
        previousLineIndentations.append(indentation)
      }
    }

    return violations
  }

  private func ignoreCompilerDirective(line: Line, in file: SwiftSource) -> Bool {
    if options.includeCompilerDirectives {
      return false
    }
    if file.syntaxMap.tokens(inByteRange: line.byteRange).kinds.first == .buildconfigKeyword {
      return true
    }
    return false
  }

  private func ignoreComment(line: Line, in file: SwiftSource) -> Bool {
    if options.includeComments {
      return false
    }
    let syntaxKindsInLine = Set(file.syntaxMap.tokens(inByteRange: line.byteRange).kinds)
    if syntaxKindsInLine.isNotEmpty,
      SourceKitSyntaxKind.commentKinds.isSuperset(of: syntaxKindsInLine)
    {
      return true
    }
    return false
  }

  private func ignoreMultilineStrings(line: Line, in file: SwiftSource) -> Bool {
    if options.includeMultilineStrings {
      return false
    }

    // A multiline string content line is characterized by beginning with a token of kind string whose range's lower
    // bound is smaller than that of the line itself.
    let tokensInLine = file.syntaxMap.tokens(inByteRange: line.byteRange)
    guard
      let firstToken = tokensInLine.first,
      firstToken.kind == .string,
      firstToken.range.lowerBound < line.byteRange.lowerBound
    else {
      return false
    }

    // Closing delimiters of a multiline string should follow the defined indentation. The Swift compiler requires
    // those delimiters to be on their own line so we need to consider the number of tokens as well as the upper
    // bounds.
    return tokensInLine.count > 1 || line.byteRange.upperBound < firstToken.range.upperBound
  }

  /// Validates whether the indentation of a specific line is valid based on the indentation of the previous line.
  ///
  /// - parameter indentation:     The indentation of the line to validate.
  /// - parameter lastIndentation: The indentation of the previous line.
  ///
  /// - returns: Whether the specified indentation is valid.
  private func validate(
    indentation: Indentation,
    comparingTo lastIndentation: Indentation
  ) -> Bool {
    let currentSpaceEquivalent = indentation.spacesEquivalent(
      indentationWidth: options.indentationWidth,
    )
    let lastSpaceEquivalent = lastIndentation.spacesEquivalent(
      indentationWidth: options.indentationWidth,
    )

    return
      // Allow indent by indentationWidth
      currentSpaceEquivalent == lastSpaceEquivalent + options.indentationWidth
      || ((lastSpaceEquivalent - currentSpaceEquivalent) >= 0
        && (lastSpaceEquivalent - currentSpaceEquivalent).isMultiple(
          of: options.indentationWidth,
        ))  // Allow unindent if it stays in the grid
  }
}
