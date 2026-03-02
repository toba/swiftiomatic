import Foundation

extension String {
  private func countOfTrailingCharacters(in characterSet: CharacterSet) -> Int {
    var count = 0
    for char in unicodeScalars.lazy.reversed() {
      if !characterSet.contains(char) {
        break
      }
      count += 1
    }
    return count
  }

  fileprivate func trailingNewlineCount() -> Int? {
    countOfTrailingCharacters(in: .newlines)
  }
}

struct TrailingNewlineRule: CorrectableRule, SyntaxOnlyRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = TrailingNewlineConfiguration()

  func validate(file: SwiftSource) -> [RuleViolation] {
    if file.contents.trailingNewlineCount() == 1 {
      return []
    }
    return [
      RuleViolation(
        ruleDescription: Self.description,
        severity: options.severity,
        location: Location(file: file.path, line: max(file.lines.count, 1)),
      )
    ]
  }

  func correct(file: SwiftSource) -> Int {
    guard let count = file.contents.trailingNewlineCount(), count != 1 else {
      return 0
    }
    guard let lastLineRange = file.lines.last?.range else {
      return 0
    }
    if file.ruleEnabled(violatingRanges: [lastLineRange], for: self).isEmpty {
      return 0
    }
    if count < 1 {
      file.append("\n")
    } else {
      let index = file.contents.index(file.contents.endIndex, offsetBy: 1 - count)
      file.write(file.contents[..<index])
    }
    return 1
  }
}
