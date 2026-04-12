import SwiftiomaticSyntax

struct PreferSwiftTestingAssertionsRule {
  static let id = "prefer_swift_testing_assertions"
  static let name = "Prefer Swift Testing Assertions"
  static let summary =
    "Individual XCTest assertion calls can be replaced with Swift Testing equivalents"
  static let isCorrectable = true
  static var relatedRuleIDs: [String] { ["prefer_swift_testing"] }

  static var nonTriggeringExamples: [Example] {
    [
      Example("#expect(value == 42)"),
      Example("#expect(items.isEmpty)"),
      Example("try #require(optionalValue)"),
      Example("Issue.record(\"something went wrong\")"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓XCTAssertEqual(a, b)"),
      Example("↓XCTAssertNotEqual(a, b)"),
      Example("↓XCTAssertTrue(value)"),
      Example("↓XCTAssertFalse(value)"),
      Example("↓XCTAssertNil(value)"),
      Example("↓XCTAssertNotNil(value)"),
      Example("↓XCTAssertGreaterThan(a, b)"),
      Example("↓XCTAssertLessThan(a, b)"),
      Example("↓XCTAssertGreaterThanOrEqual(a, b)"),
      Example("↓XCTAssertLessThanOrEqual(a, b)"),
      Example("↓XCTFail(\"msg\")"),
      Example("try ↓XCTUnwrap(optionalValue)"),
      Example("↓XCTAssertThrowsError(try foo())"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("↓XCTAssertEqual(a, b)"): Example("#expect(a == b)"),
      Example("↓XCTAssertNotEqual(a, b)"): Example("#expect(a != b)"),
      Example("↓XCTAssertTrue(value)"): Example("#expect(value)"),
      Example("↓XCTAssertFalse(value)"): Example("#expect(!value)"),
      Example("↓XCTAssertNil(value)"): Example("#expect(value == nil)"),
      Example("↓XCTAssertNotNil(value)"): Example("#expect(value != nil)"),
      Example("↓XCTAssertGreaterThan(a, b)"): Example("#expect(a > b)"),
      Example("↓XCTAssertLessThan(a, b)"): Example("#expect(a < b)"),
      Example("↓XCTAssertGreaterThanOrEqual(a, b)"): Example("#expect(a >= b)"),
      Example("↓XCTAssertLessThanOrEqual(a, b)"): Example("#expect(a <= b)"),
      Example("↓XCTFail(\"msg\")"): Example("Issue.record(\"msg\")"),
      Example("try ↓XCTUnwrap(optionalValue)"): Example("try #require(optionalValue)"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension PreferSwiftTestingAssertionsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferSwiftTestingAssertionsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private static let knownAssertions: Set<String> = [
      "XCTAssertEqual", "XCTAssertNotEqual",
      "XCTAssertTrue", "XCTAssertFalse",
      "XCTAssertNil", "XCTAssertNotNil",
      "XCTAssertGreaterThan", "XCTAssertLessThan",
      "XCTAssertGreaterThanOrEqual", "XCTAssertLessThanOrEqual",
      "XCTFail", "XCTUnwrap", "XCTAssertThrowsError",
    ]

    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription
      guard Self.knownAssertions.contains(callee) else { return }

      let args = significantArgs(from: node)
      let replacement = buildReplacement(callee: callee, args: args)
      let isCorrectable = callee != "XCTAssertThrowsError"

      var correction: SyntaxViolation.Correction?
      if isCorrectable, let replacement {
        if callee == "XCTUnwrap" {
          // XCTUnwrap → try #require — "try" already at call site, replace from callee
          correction = .init(
            start: node.calledExpression.positionAfterSkippingLeadingTrivia,
            end: node.endPositionBeforeTrailingTrivia,
            replacement: replacement,
          )
        } else {
          correction = .init(
            start: node.positionAfterSkippingLeadingTrivia,
            end: node.endPositionBeforeTrailingTrivia,
            replacement: replacement,
          )
        }
      }

      violations.append(
        SyntaxViolation(
          position: callee == "XCTUnwrap"
            ? node.calledExpression.positionAfterSkippingLeadingTrivia
            : node.positionAfterSkippingLeadingTrivia,
          reason: "\(callee) can be replaced with Swift Testing equivalent",
          correction: correction,
          confidence: .high,
          suggestion: replacement,
        )
      )
    }

    private func buildReplacement(callee: String, args: [String]) -> String? {
      switch callee {
      case "XCTAssertEqual" where args.count >= 2:
        "#expect(\(args[0]) == \(args[1]))"
      case "XCTAssertNotEqual" where args.count >= 2:
        "#expect(\(args[0]) != \(args[1]))"
      case "XCTAssertGreaterThan" where args.count >= 2:
        "#expect(\(args[0]) > \(args[1]))"
      case "XCTAssertLessThan" where args.count >= 2:
        "#expect(\(args[0]) < \(args[1]))"
      case "XCTAssertGreaterThanOrEqual" where args.count >= 2:
        "#expect(\(args[0]) >= \(args[1]))"
      case "XCTAssertLessThanOrEqual" where args.count >= 2:
        "#expect(\(args[0]) <= \(args[1]))"
      case "XCTAssertTrue" where !args.isEmpty:
        "#expect(\(args[0]))"
      case "XCTAssertFalse" where !args.isEmpty:
        "#expect(!\(args[0]))"
      case "XCTAssertNil" where !args.isEmpty:
        "#expect(\(args[0]) == nil)"
      case "XCTAssertNotNil" where !args.isEmpty:
        "#expect(\(args[0]) != nil)"
      case "XCTFail":
        args.isEmpty ? "Issue.record()" : "Issue.record(\(args[0]))"
      case "XCTUnwrap" where !args.isEmpty:
        "#require(\(args[0]))"
      case "XCTAssertThrowsError" where !args.isEmpty:
        "#expect(throws: (any Error).self) { \(args[0]) }"
      default:
        nil
      }
    }

    private func significantArgs(from node: FunctionCallExprSyntax) -> [String] {
      let skipLabels: Set<String> = ["message", "file", "line"]
      return node.arguments
        .filter { arg in
          guard let label = arg.label?.text else { return true }
          return !skipLabels.contains(label)
        }
        .map(\.expression.trimmedDescription)
    }
  }
}
