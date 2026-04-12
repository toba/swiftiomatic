import SwiftiomaticSyntax

struct AttributePlacementRule {
  static let id = "attribute_placement"
  static let name = "Attribute Placement"
  static let summary = "Attributes should be on their own line for functions and types, same line for variables and imports"
  static let isOptIn = true
  static let isCorrectable = true
  static let rationale: String? = """
    Erica Sadun says:

    > My take on things after the poll and after talking directly with a number of \
    developers is this: Placing attributes like `@objc`, `@testable`, `@available`, `@discardableResult` on \
    their own lines before a member declaration has become a conventional Swift style.

    > This approach limits declaration length. It allows a member to float below its attribute and supports \
    flush-left access modifiers, so `internal`, `public`, etc appear in the leftmost column. Many developers \
    mix-and-match styles for short Swift attributes like `@objc`

    See https://ericasadun.com/2016/10/02/quick-style-survey/ for discussion.

    Swiftiomatic's rule requires attributes to be on their own lines for functions and types, but on the same line \
    for variables and imports.

    When `inline_when_fits` is enabled, a single argument-less attribute on a function or type declaration \
    will be placed on the same line if the combined result fits within `max_width`.
    """

  static var corrections: [Example: Example] {
    [
      Example(
        """
        ↓@Test
        func foo() { }
        """,
        configuration: ["inline_when_fits": true, "max_width": 120],
      ): Example(
        """
        @Test func foo() { }
        """
      ),
      Example(
        """
        ↓@MainActor
        func update() { }
        """,
        configuration: ["inline_when_fits": true, "max_width": 120],
      ): Example(
        """
        @MainActor func update() { }
        """
      ),
    ]
  }

  var options = AttributePlacementOptions()
}

// MARK: - FormatAwareRule

extension AttributePlacementRule: FormatAwareRule {
  static var formatConfigKeys: Set<String> { ["max_width"] }
}

extension AttributePlacementRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AttributePlacementRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AttributeListSyntax) {
      guard let helper = node.makeHelper(locationConverter: locationConverter) else {
        return
      }

      let attributesAndPlacements = node.attributesAndPlacements(
        configuration: configuration,
        shouldBeOnSameLine: helper.shouldBeOnSameLine,
      )

      let hasViolation = helper.hasViolation(
        locationConverter: locationConverter,
        attributesAndPlacements: attributesAndPlacements,
        attributesWithArgumentsAlwaysOnNewLine: configuration
          .attributesWithArgumentsAlwaysOnNewLine,
      )

      switch hasViolation {
      case .argumentsAlwaysOnNewLineViolation:
        let reason = """
          Attributes with arguments or inside always_on_line_above must be on a new line \
          instead of the same line
          """

        violations.append(
          SyntaxViolation(
            position: helper.violationPosition,
            reason: reason,
            severity: configuration.severityConfiguration.severity,
          ),
        )
        return
      case .violation:
        violations.append(helper.violationPosition)
        return
      case .noViolation:
        break
      }

      let linesForAttributes =
        attributesAndPlacements
        .filter { $1 == .dedicatedLine }
        .map { $0.0.endLine(locationConverter: locationConverter) }

      if linesForAttributes.isEmpty {
        return
      }
      if !linesForAttributes.contains(helper.keywordLine - 1) {
        violations.append(helper.violationPosition)
        return
      }

      let hasMultipleNewlines = node.children(viewMode: .sourceAccurate).enumerated()
        .contains {
          index, element in
          if index > 0, element.leadingTrivia.hasMultipleNewlines == true {
            return true
          }
          return element.trailingTrivia.hasMultipleNewlines == true
        }

      if hasMultipleNewlines {
        violations.append(helper.violationPosition)
        return
      }

      // inline_when_fits: collapse a single argument-less attribute onto the declaration line
      // when the combined result fits within max_width
      checkInlineWhenFits(node: node, helper: helper)
    }

    private func checkInlineWhenFits(node: AttributeListSyntax, helper: RuleHelper) {
      guard configuration.inlineWhenFits else { return }
      guard !helper.shouldBeOnSameLine else { return }

      let attributes = node.children(viewMode: .sourceAccurate)
        .compactMap { $0.as(AttributeSyntax.self) }
      guard attributes.count == 1, let attribute = attributes.first else { return }
      guard attribute.arguments == nil else { return }

      let atPrefixedName = "@\(attribute.attributeNameText)"
      guard !configuration.alwaysOnNewLine.contains(atPrefixedName) else { return }

      // Attribute must be on a separate line from the keyword
      let attrLocation = locationConverter.location(
        for: attribute.positionAfterSkippingLeadingTrivia
      )
      guard attrLocation.line != helper.keywordLine else { return }

      // Calculate combined width: indent + "@Attr" + " " + keywordLineContent
      let indent = attrLocation.column - 1
      let attrText = attribute.trimmedDescription
      let keywordLineIndex = helper.keywordLine - 1
      guard keywordLineIndex >= 0, keywordLineIndex < file.lines.count else { return }
      let keywordLineContent = file.lines[keywordLineIndex].content
      let strippedLength = keywordLineContent.drop(while: { $0 == " " || $0 == "\t" }).count
      let combinedWidth = indent + attrText.count + 1 + strippedLength

      guard combinedWidth <= configuration.maxWidth else { return }

      // Build correction: replace trivia between attribute and next token with a space
      guard let lastAttrToken = node.lastToken(viewMode: .sourceAccurate),
        let nextToken = lastAttrToken.nextToken(viewMode: .sourceAccurate)
      else { return }

      let correction = SyntaxViolation.Correction(
        start: lastAttrToken.endPositionBeforeTrailingTrivia,
        end: nextToken.positionAfterSkippingLeadingTrivia,
        replacement: " ",
      )

      violations.append(
        SyntaxViolation(
          position: attribute.positionAfterSkippingLeadingTrivia,
          reason: "Attribute '\(atPrefixedName)' can be placed on the same line as the declaration",
          correction: correction,
        ),
      )
    }
  }
}

extension SyntaxProtocol {
  fileprivate func startLine(locationConverter: SourceLocationConverter) -> Int? {
    locationConverter.location(for: positionAfterSkippingLeadingTrivia).line
  }

  fileprivate func endLine(locationConverter: SourceLocationConverter) -> Int? {
    locationConverter.location(for: endPositionBeforeTrailingTrivia).line
  }
}

extension Trivia {
  fileprivate var hasMultipleNewlines: Bool {
    reduce(0) { $0 + $1.numberOfNewlines } > 1
  }
}

extension TriviaPiece {
  fileprivate var numberOfNewlines: Int {
    if case .newlines(let numberOfNewlines) = self {
      return numberOfNewlines
    }
    return 0
  }
}

private enum AttributePlacement {
  case sameLineAsDeclaration
  case dedicatedLine
}

private enum Violation {
  case argumentsAlwaysOnNewLineViolation
  case noViolation
  case violation
}

private struct RuleHelper {
  let violationPosition: AbsolutePosition
  let keywordLine: Int
  let shouldBeOnSameLine: Bool

  func hasViolation(
    locationConverter: SourceLocationConverter,
    attributesAndPlacements: [(AttributeSyntax, AttributePlacement)],
    attributesWithArgumentsAlwaysOnNewLine: Bool,
  ) -> (Violation) {
    var linesWithAttributes: Set<Int> = [keywordLine]
    for (attribute, placement) in attributesAndPlacements {
      guard let attributeStartLine = attribute.startLine(locationConverter: locationConverter)
      else {
        continue
      }

      switch placement {
      case .sameLineAsDeclaration:
        if attributeStartLine != keywordLine {
          return .violation
        }
      case .dedicatedLine:
        let hasViolation =
          attributeStartLine == keywordLine
          || linesWithAttributes
            .contains(attributeStartLine)
        linesWithAttributes.insert(attributeStartLine)
        if hasViolation {
          if attributesWithArgumentsAlwaysOnNewLine, shouldBeOnSameLine {
            return .argumentsAlwaysOnNewLineViolation
          }
          return .violation
        }
      }
    }
    return .noViolation
  }
}

extension AttributeListSyntax {
  fileprivate func attributesAndPlacements(
    configuration: AttributePlacementOptions, shouldBeOnSameLine: Bool,
  )
    -> [(AttributeSyntax, AttributePlacement)]
  {
    children(viewMode: .sourceAccurate)
      .compactMap { $0.as(AttributeSyntax.self) }
      .map { attribute in
        let atPrefixedName = "@\(attribute.attributeNameText)"
        if configuration.alwaysOnSameLine.contains(atPrefixedName) {
          return (attribute, .sameLineAsDeclaration)
        }
        if configuration.alwaysOnNewLine.contains(atPrefixedName) {
          return (attribute, .dedicatedLine)
        }
        if attribute.arguments != nil,
          configuration.attributesWithArgumentsAlwaysOnNewLine
        {
          return (attribute, .dedicatedLine)
        }

        return shouldBeOnSameLine
          ? (attribute, .sameLineAsDeclaration) : (attribute, .dedicatedLine)
      }
  }

  // sm:disable:next cyclomatic_complexity
  fileprivate func makeHelper(locationConverter: SourceLocationConverter) -> RuleHelper? {
    guard let parent else {
      return nil
    }

    let keyword: any SyntaxProtocol
    let shouldBeOnSameLine: Bool
    if let funcKeyword = parent.as(FunctionDeclSyntax.self)?.funcKeyword {
      keyword = funcKeyword
      shouldBeOnSameLine = false
    } else if let initKeyword = parent.as(InitializerDeclSyntax.self)?.initKeyword {
      keyword = initKeyword
      shouldBeOnSameLine = false
    } else if let enumKeyword = parent.as(EnumDeclSyntax.self)?.enumKeyword {
      keyword = enumKeyword
      shouldBeOnSameLine = false
    } else if let structKeyword = parent.as(StructDeclSyntax.self)?.structKeyword {
      keyword = structKeyword
      shouldBeOnSameLine = false
    } else if let classKeyword = parent.as(ClassDeclSyntax.self)?.classKeyword {
      keyword = classKeyword
      shouldBeOnSameLine = false
    } else if let extensionKeyword = parent.as(ExtensionDeclSyntax.self)?.extensionKeyword {
      keyword = extensionKeyword
      shouldBeOnSameLine = false
    } else if let protocolKeyword = parent.as(ProtocolDeclSyntax.self)?.protocolKeyword {
      keyword = protocolKeyword
      shouldBeOnSameLine = false
    } else if let importTok = parent.as(ImportDeclSyntax.self)?.importKeyword {
      keyword = importTok
      shouldBeOnSameLine = true
    } else if let letOrVarKeyword = parent.as(VariableDeclSyntax.self)?.bindingSpecifier {
      keyword = letOrVarKeyword
      shouldBeOnSameLine = true
    } else {
      return nil
    }

    guard let keywordLine = keyword.startLine(locationConverter: locationConverter) else {
      return nil
    }

    return RuleHelper(
      violationPosition: keyword.positionAfterSkippingLeadingTrivia,
      keywordLine: keywordLine,
      shouldBeOnSameLine: shouldBeOnSameLine,
    )
  }
}
