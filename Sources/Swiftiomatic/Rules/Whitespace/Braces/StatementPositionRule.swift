import Foundation

struct StatementPositionRule: CorrectableRule {
  var configuration = StatementPositionConfiguration()

  static let description = RuleDescription(
    identifier: "statement_position",
    name: "Statement Position",
    description:
      "Else and catch should be on the same line, one space after the previous declaration",
    nonTriggeringExamples: [
      Example("} else if {"),
      Example("} else {"),
      Example("} catch {"),
      Example("\"}else{\""),
      Example("struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)"),
      Example("struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)"),
    ],
    triggeringExamples: [
      Example("↓}else if {"),
      Example("↓}  else {"),
      Example("↓}\ncatch {"),
      Example("↓}\n\t  catch {"),
    ],
    corrections: [
      Example("↓}\n else {"): Example("} else {"),
      Example("↓}\n   else if {"): Example("} else if {"),
      Example("↓}\n catch {"): Example("} catch {"),
    ],
  )

  static let uncuddledDescription = RuleDescription(
    identifier: "statement_position",
    name: "Statement Position",
    description: "Else and catch should be on the next line, with equal indentation to the "
      + "previous declaration",
    nonTriggeringExamples: [
      Example("  }\n  else if {"),
      Example("    }\n    else {"),
      Example("  }\n  catch {"),
      Example("  }\n\n  catch {"),
      Example("\n\n  }\n  catch {"),
      Example("\"}\nelse{\""),
      Example("struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)"),
      Example("struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)"),
    ],
    triggeringExamples: [
      Example("↓  }else if {"),
      Example("↓}\n  else {"),
      Example("↓  }\ncatch {"),
      Example("↓}\n\t  catch {"),
    ],
    corrections: [
      Example("  }else if {"): Example("  }\n  else if {"),
      Example("}\n  else {"): Example("}\nelse {"),
      Example("  }\ncatch {"): Example("  }\n  catch {"),
      Example("}\n\t  catch {"): Example("}\ncatch {"),
    ],
  )

  func validate(file: SwiftSource) -> [RuleViolation] {
    switch configuration.statementMode {
    case .default:
      return defaultValidate(file: file)
    case .uncuddledElse:
      return uncuddledValidate(file: file)
    }
  }

  func correct(file: SwiftSource) -> Int {
    switch configuration.statementMode {
    case .default:
      defaultCorrect(file: file)
    case .uncuddledElse:
      uncuddledCorrect(file: file)
    }
  }
}

/// Default Behaviors
extension StatementPositionRule {
  /// match literal '}'
  /// followed by 1) nothing, 2) two+ whitespace/newlines or 3) newlines or tabs
  /// followed by 'else' or 'catch' literals
  fileprivate static let defaultPattern = "\\}(?:[\\s\\n\\r]{2,}|[\\n\\t\\r]+)?\\b(else|catch)\\b"

  fileprivate func defaultValidate(file: SwiftSource) -> [RuleViolation] {
    defaultViolationRanges(in: file, matching: Self.defaultPattern).compactMap { range in
      RuleViolation(
        ruleDescription: Self.description,
        severity: configuration.severity,
        location: Location(file: file, stringIndex: range.lowerBound),
      )
    }
  }

  fileprivate func defaultViolationRanges(in file: SwiftSource, matching pattern: String)
    -> [Range<String.Index>]
  {
    file.match(pattern: pattern).filter { _, syntaxKinds in
      syntaxKinds.starts(with: [.keyword])
    }.compactMap(\.0)
  }

  fileprivate func defaultCorrect(file: SwiftSource) -> Int {
    let violations = defaultViolationRanges(in: file, matching: Self.defaultPattern)
    let matches = file.ruleEnabled(violatingRanges: violations, for: self)
    if matches.isEmpty {
      return 0
    }
    let regularExpression = regex(Self.defaultPattern)
    var contents = file.contents
    for range in matches.reversed() {
      contents = regularExpression.replacing(in: contents, range: range) { match in
        "} \(match.output[1].substring ?? "")"
      }
    }
    file.write(contents)
    return matches.count
  }
}

/// Uncuddled Behaviors
extension StatementPositionRule {
  fileprivate func uncuddledValidate(file: SwiftSource) -> [RuleViolation] {
    uncuddledViolationRanges(in: file).compactMap { range in
      RuleViolation(
        ruleDescription: Self.uncuddledDescription,
        severity: configuration.severity,
        location: Location(file: file, stringIndex: range.lowerBound),
      )
    }
  }

  /// match literal '}'
  /// preceded by whitespace (or nothing)
  /// followed by 1) nothing, 2) two+ whitespace/newlines or 3) newlines or tabs
  /// followed by newline and the same amount of whitespace then 'else' or 'catch' literals
  fileprivate static let uncuddledPattern = "([ \t]*)\\}(\\n+)?([ \t]*)\\b(else|catch)\\b"

  fileprivate static let uncuddledRegex = regex(uncuddledPattern, options: [])

  /// A validated match that holds ranges for each capture group.
  private struct UncuddledMatch {
    let fullRange: Range<String.Index>
    let group1Range: Range<String.Index>  // leading whitespace before }
    let group2Range: Range<String.Index>?  // newlines between } and else/catch
    let group3Range: Range<String.Index>  // whitespace before else/catch
  }

  private static func uncuddledMatches(in file: SwiftSource) -> [UncuddledMatch] {
    return uncuddledRegex.matches(in: file).compactMap { match in
      let fullRange = match.range
      // Group 1: leading whitespace
      guard let g1Sub = match.output[1].substring else { return nil }
      let g1Range = g1Sub.startIndex..<g1Sub.endIndex
      // Group 2: newlines (optional)
      let g2Range = match.output[2].substring.map { sub in
        sub.startIndex..<sub.endIndex
      }
      // Group 3: whitespace before keyword
      guard let g3Sub = match.output[3].substring else { return nil }
      let g3Range = g3Sub.startIndex..<g3Sub.endIndex

      return UncuddledMatch(
        fullRange: fullRange,
        group1Range: g1Range,
        group2Range: g2Range,
        group3Range: g3Range,
      )
    }
  }

  private static func uncuddledMatchValidator(contents: StringView) -> (
    (UncuddledMatch) -> UncuddledMatch?
  ) {
    { match in
      guard let group2Range = match.group2Range, !group2Range.isEmpty else {
        return match
      }
      let whitespace1 = String(contents.string[match.group1Range])
      let whitespace2 = String(contents.string[match.group3Range])
      if whitespace1 == whitespace2 {
        return nil
      }
      return match
    }
  }

  private static func uncuddledMatchFilter(
    contents: StringView,
    syntaxMap: ResolvedSyntaxMap,
  ) -> ((UncuddledMatch) -> Bool) {
    { match in
      let matchByteRange = contents.stringRangeToByteRange(match.fullRange)
      return syntaxMap.kinds(inByteRange: matchByteRange) == [.keyword]
    }
  }

  fileprivate func uncuddledViolationRanges(in file: SwiftSource) -> [Range<String.Index>] {
    let contents = file.stringView
    let syntaxMap = file.syntaxMap
    let matches = Self.uncuddledMatches(in: file)
    let validator = Self.uncuddledMatchValidator(contents: contents)
    let filterMatches = Self.uncuddledMatchFilter(contents: contents, syntaxMap: syntaxMap)

    return matches.compactMap(validator).filter(filterMatches).map(\.fullRange)
  }

  fileprivate func uncuddledCorrect(file: SwiftSource) -> Int {
    var contents = file.contents
    let syntaxMap = file.syntaxMap
    let matches = Self.uncuddledMatches(in: file)
    let validator = Self.uncuddledMatchValidator(contents: file.stringView)
    let filterRanges = Self.uncuddledMatchFilter(
      contents: file.stringView,
      syntaxMap: syntaxMap,
    )
    let validMatches = matches.compactMap(validator).filter(filterRanges)
      .filter { file.ruleEnabled(violatingRanges: [$0.fullRange], for: self).isNotEmpty }
    if validMatches.isEmpty {
      return 0
    }
    for match in validMatches.reversed() {
      var whitespace = String(contents[match.group1Range])
      let newLines: String
      if let group2Range = match.group2Range {
        newLines = String(contents[group2Range])
      } else {
        newLines = ""
      }
      if !whitespace.hasPrefix("\n"), newLines != "\n" {
        whitespace.insert("\n", at: whitespace.startIndex)
      }
      contents.replaceSubrange(match.group3Range, with: whitespace)
    }
    file.write(contents)
    return validMatches.count
  }
}
