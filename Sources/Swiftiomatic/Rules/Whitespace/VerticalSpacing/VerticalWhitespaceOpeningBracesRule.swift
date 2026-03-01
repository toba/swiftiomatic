import Foundation

extension SwiftSource {
  fileprivate func violatingRanges(for pattern: String) -> [Range<String.Index>] {
    match(pattern: pattern, excludingSyntaxKinds: SourceKitSyntaxKind.commentAndStringKinds)
  }
}

struct VerticalWhitespaceOpeningBracesRule: Rule {
  var options = SeverityConfiguration<Self>(.warning)

  private static let nonTriggeringExamples = [
    Example("[1, 2].map { $0 }.foo()"),
    Example("[1, 2].map { $0 }.filter { num in true }"),
    Example("// [1, 2].map { $0 }.filter { num in true }"),
    Example(
      """
      /*
          class X {

              let x = 5

          }
      */
      """,
    ),
  ]

  private static let violatingToValidExamples: [Example: Example] = [
    Example(
      """
      if x == 5 {
      ↓
        print("x is 5")
      }
      """,
    ): Example(
      """
      if x == 5 {
        print("x is 5")
      }
      """,
    ),
    Example(
      """
      if x == 5 {
      ↓

        print("x is 5")
      }
      """,
    ): Example(
      """
      if x == 5 {
        print("x is 5")
      }
      """,
    ),
    Example(
      """
      struct MyStruct {
      ↓
        let x = 5
      }
      """,
    ): Example(
      """
      struct MyStruct {
        let x = 5
      }
      """,
    ),
    Example(
      """
      class X {
        struct Y {
      ↓
          class Z {
          }
        }
      }
      """,
    ): Example(
      """
      class X {
        struct Y {
          class Z {
          }
        }
      }
      """,
    ),
    Example(
      """
      [
      ↓
      1,
      2,
      3
      ]
      """,
    ): Example(
      """
      [
      1,
      2,
      3
      ]
      """,
    ),
    Example(
      """
      foo(
      ↓
        x: 5,
        y:6
      )
      """,
    ): Example(
      """
      foo(
        x: 5,
        y:6
      )
      """,
    ),
    Example(
      """
      func foo() {
      ↓
        run(5) { x in
          print(x)
        }
      }
      """,
    ): Example(
      """
      func foo() {
        run(5) { x in
          print(x)
        }
      }
      """,
    ),
    Example(
      """
      KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
      ↓
          guard let img = image else { return }
      }
      """,
    ): Example(
      """
      KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
          guard let img = image else { return }
      }
      """,
    ),
    Example(
      """
      foo({ }) { _ in
      ↓
        self.dismiss(animated: false, completion: {
        })
      }
      """,
    ): Example(
      """
      foo({ }) { _ in
        self.dismiss(animated: false, completion: {
        })
      }
      """,
    ),
  ]

  private let pattern = "([{(\\[][ \\t]*(?:[^\\n{]+ in[ \\t]*$)?)((?:\\n[ \\t]*)+)(\\n)"
}

extension VerticalWhitespaceOpeningBracesRule {
  static let description = RuleDescription(
    identifier: "vertical_whitespace_opening_braces",
    name: "Vertical Whitespace after Opening Braces",
    description: "Don't include vertical whitespace (empty line) after opening braces",
    isOptIn: true,
    nonTriggeringExamples: (violatingToValidExamples.values + nonTriggeringExamples).sorted(),
    triggeringExamples: Array(violatingToValidExamples.keys).sorted(),
    corrections: violatingToValidExamples.removingViolationMarkers(),
  )

  func validate(file: SwiftSource) -> [RuleViolation] {
    let patternRegex = regex(pattern)

    return file.violatingRanges(for: pattern).map { violationRange in
      let matchResult = patternRegex.firstMatch(
        in: file.contents, range: violationRange,
      )!
      let group2Sub = matchResult.output[2].substring!
      let violationIndex = file.contents.index(after: group2Sub.startIndex)

      return RuleViolation(
        ruleDescription: Self.description,
        severity: options.severity,
        location: Location(file: file, stringIndex: violationIndex),
      )
    }
  }
}

extension VerticalWhitespaceOpeningBracesRule: CorrectableRule {
  func correct(file: SwiftSource) -> Int {
    let violatingRanges = file.ruleEnabled(
      violatingRanges: file.violatingRanges(for: pattern), for: self,
    )
    guard violatingRanges.isNotEmpty else {
      return 0
    }
    let patternRegex = regex(pattern)
    var fileContents = file.contents
    for violationRange in violatingRanges.reversed() {
      fileContents = patternRegex.replacing(in: fileContents, range: violationRange) { match in
        let g1 = match.output[1].substring.map(String.init) ?? ""
        let g3 = match.output[3].substring.map(String.init) ?? ""
        return g1 + g3
      }
    }
    file.write(fileContents)
    return violatingRanges.count
  }
}
