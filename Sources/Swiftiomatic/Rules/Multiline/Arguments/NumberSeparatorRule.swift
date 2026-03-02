import Foundation
import SwiftSyntax

struct NumberSeparatorRule {
    static let id = "number_separator"
    static let name = "Number Separator"
    static let summary = ""
    static let isCorrectable = true
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        NumberSeparatorRuleExamples.nonTriggeringExamples
    }
    static var triggeringExamples: [Example] {
        NumberSeparatorRuleExamples.triggeringExamples
    }
    static var corrections: [Example: Example] {
        NumberSeparatorRuleExamples.corrections
    }
  var options = NumberSeparatorOptions()

  static let missingSeparatorsReason = """
    Underscores should be used as thousand separators
    """
  static let misplacedSeparatorsReason = """
    Underscore(s) used as thousand separator(s) should be added after every 3 digits only
    """
}

extension NumberSeparatorRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension NumberSeparatorRule {}

extension NumberSeparatorRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType>,
    NumberSeparatorValidator
  {
    override func visitPost(_ node: FloatLiteralExprSyntax) {
      if let violation = violation(token: node.literal) {
        violations.append(
          SyntaxViolation(position: violation.position, reason: violation.reason),
        )
      }
    }

    override func visitPost(_ node: IntegerLiteralExprSyntax) {
      if let violation = violation(token: node.literal) {
        violations.append(
          SyntaxViolation(position: violation.position, reason: violation.reason),
        )
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType>,
    NumberSeparatorValidator
  {
    override func visit(_ node: FloatLiteralExprSyntax) -> ExprSyntax {
      guard let violation = violation(token: node.literal) else {
        return super.visit(node)
      }

      let newNode = node.with(
        \.literal,
        node.literal.with(
          \.tokenKind,
          .floatLiteral(violation.correction),
        ),
      )
      numberOfCorrections += 1
      return super.visit(newNode)
    }

    override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {
      guard let violation = violation(token: node.literal) else {
        return super.visit(node)
      }
      let newNode = node.with(
        \.literal, node.literal.with(\.tokenKind, .integerLiteral(violation.correction)),
      )
      numberOfCorrections += 1
      return super.visit(newNode)
    }
  }
}

private protocol NumberSeparatorValidator {
  var configuration: NumberSeparatorOptions { get }
}

private enum NumberSeparatorViolation {
  case missingSeparator(position: AbsolutePosition, correction: String)
  case misplacedSeparator(position: AbsolutePosition, correction: String)

  var reason: String {
    switch self {
    case .missingSeparator: return NumberSeparatorRule.missingSeparatorsReason
    case .misplacedSeparator: return NumberSeparatorRule.misplacedSeparatorsReason
    }
  }

  var position: AbsolutePosition {
    switch self {
    case .missingSeparator(let position, _): return position
    case .misplacedSeparator(let position, _): return position
    }
  }

  var correction: String {
    switch self {
    case .missingSeparator(_, let correction): return correction
    case .misplacedSeparator(_, let correction): return correction
    }
  }
}

extension NumberSeparatorValidator {
  fileprivate func violation(token: TokenSyntax) -> NumberSeparatorViolation? {
    let content = token.text
    guard isDecimal(number: content),
      !isInValidRanges(number: content)
    else {
      return nil
    }

    let exponential = CharacterSet(charactersIn: "eE")
    guard case let exponentialComponents = content.components(separatedBy: exponential),
      let nonExponential = exponentialComponents.first
    else {
      return nil
    }

    let components = nonExponential.components(separatedBy: ".")

    var validFraction = true
    var expectedFraction: String?
    if components.count == 2, let fractionSubstring = components.last {
      (validFraction, expectedFraction) = isValid(number: fractionSubstring, isFraction: true)
    }

    guard let integerSubstring = components.first,
      case (let valid, let expected) = isValid(number: integerSubstring, isFraction: false),
      !valid || !validFraction
    else {
      return nil
    }

    var corrected = expected
    if let fraction = expectedFraction {
      corrected += "." + fraction
    }

    if exponentialComponents.count == 2, let exponential = exponentialComponents.last {
      let exponentialSymbol = content.contains("e") ? "e" : "E"
      corrected += exponentialSymbol + exponential
    }

    if content.contains("_") {
      return .misplacedSeparator(
        position: token.positionAfterSkippingLeadingTrivia, correction: corrected,
      )
    }
    return .missingSeparator(
      position: token.positionAfterSkippingLeadingTrivia, correction: corrected,
    )
  }

  private func isDecimal(number: String) -> Bool {
    let lowercased = number.lowercased()
    let prefixes = ["0x", "0o", "0b"].flatMap { [$0, "-\($0)", "+\($0)"] }

    return !prefixes.contains(where: lowercased.hasPrefix)
  }

  private func isInValidRanges(number: String) -> Bool {
    let doubleValue = Double(number.replacingOccurrences(of: "_", with: ""))
    if let doubleValue,
      configuration.excludeRanges.contains(where: { $0.contains(doubleValue) })
    {
      return true
    }

    return false
  }

  private func isValid(number: String, isFraction: Bool) -> (Bool, String) {
    var correctComponents = [String]()
    let clean = number.replacingOccurrences(of: "_", with: "")

    let minimumLength: Int
    if isFraction {
      minimumLength = configuration.minimumFractionLength ?? .max
    } else {
      minimumLength = configuration.minimumLength
    }

    let shouldAddSeparators = clean.count >= minimumLength

    var numerals = 0
    for char in reversedIfNeeded(clean, reversed: !isFraction) {
      defer { correctComponents.append(String(char)) }
      guard char.unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
      else { continue }

      if numerals.isMultiple(of: 3), numerals > 0, shouldAddSeparators {
        correctComponents.append("_")
      }
      numerals += 1
    }

    let expected = reversedIfNeeded(correctComponents, reversed: !isFraction).joined()
    return (expected == number, expected)
  }

  private func reversedIfNeeded<T: Collection>(_ collection: T, reversed: Bool) -> [T.Element] {
    if reversed {
      return collection.reversed()
    }

    return Array(collection)
  }
}
