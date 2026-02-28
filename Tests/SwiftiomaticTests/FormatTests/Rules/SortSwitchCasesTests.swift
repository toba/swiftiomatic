import Testing

@testable import Swiftiomatic

@Suite struct SortSwitchCasesTests {
  @Test func sortedSwitchCaseNestedSwitchOneCaseDoesNothing() {
    let input = """
      switch result {
      case let .success(value):
          switch result {
          case .success:
              print("success")
          case .value:
              print("value")
          }

      case .failure:
          guard self.bar else {
              print(self.bar)
              return
          }
          print(self.bar)
      }
      """

    testFormatting(
      for: input, rule: .sortSwitchCases,
      exclude: [.redundantSelf, .blankLinesAfterGuardStatements])
  }

  @Test func sortedSwitchCaseMultilineWithOneComment() {
    let input = """
      switch self {
      case let .type, // something
           let .conditionalCompilation:
          break
      }
      """
    let output = """
      switch self {
      case let .conditionalCompilation,
           let .type: // something
          break
      }
      """
    testFormatting(for: input, output, rule: .sortSwitchCases)
  }

  @Test func sortedSwitchCaseMultilineWithComments() {
    let input = """
      switch self {
      case let .type, // typeComment
           let .conditionalCompilation: // conditionalCompilationComment
          break
      }
      """
    let output = """
      switch self {
      case let .conditionalCompilation, // conditionalCompilationComment
           let .type: // typeComment
          break
      }
      """
    testFormatting(for: input, output, rule: .sortSwitchCases, exclude: [.indent])
  }

  @Test func sortedSwitchCaseMultilineWithCommentsAndMoreThanOneCasePerLine() {
    let input = """
      switch self {
      case let .type, // typeComment
           let .type1, .type2,
           let .conditionalCompilation: // conditionalCompilationComment
          break
      }
      """
    let output = """
      switch self {
      case let .conditionalCompilation, // conditionalCompilationComment
           let .type, // typeComment
           let .type1,
           .type2:
          break
      }
      """
    testFormatting(for: input, output, rule: .sortSwitchCases)
  }

  @Test func sortedSwitchCaseMultiline() {
    let input = """
      switch self {
      case let .type,
           let .conditionalCompilation:
          break
      }
      """
    let output = """
      switch self {
      case let .conditionalCompilation,
           let .type:
          break
      }
      """
    testFormatting(for: input, output, rule: .sortSwitchCases)
  }

  @Test func sortedSwitchCaseMultipleAssociatedValues() {
    let input = """
      switch self {
      case let .b(whatever, whatever2), .a(whatever):
          break
      }
      """
    let output = """
      switch self {
      case .a(whatever), let .b(whatever, whatever2):
          break
      }
      """
    testFormatting(
      for: input, output, rule: .sortSwitchCases,
      exclude: [.wrapSwitchCases])
  }

  @Test func sortedSwitchCaseOneLineWithoutSpaces() {
    let input = """
      switch self {
      case .b,.a:
          break
      }
      """
    let output = """
      switch self {
      case .a,.b:
          break
      }
      """
    testFormatting(
      for: input, output, rule: .sortSwitchCases,
      exclude: [.wrapSwitchCases, .spaceAroundOperators])
  }

  @Test func sortedSwitchCaseLet() {
    let input = """
      switch self {
      case let .b(whatever), .a(whatever):
          break
      }
      """
    let output = """
      switch self {
      case .a(whatever), let .b(whatever):
          break
      }
      """
    testFormatting(
      for: input, output, rule: .sortSwitchCases,
      exclude: [.wrapSwitchCases])
  }

  @Test func sortedSwitchCaseOneCaseDoesNothing() {
    let input = """
      switch self {
      case "a":
          break
      }
      """
    testFormatting(for: input, rule: .sortSwitchCases)
  }

  @Test func sortedSwitchStrings() {
    let input = """
      switch self {
      case "GET", "POST", "PUT", "DELETE":
          break
      }
      """
    let output = """
      switch self {
      case "DELETE", "GET", "POST", "PUT":
          break
      }
      """
    testFormatting(
      for: input, output, rule: .sortSwitchCases,
      exclude: [.wrapSwitchCases])
  }

  @Test func sortedSwitchWhereConditionNotLastCase() {
    let input = """
      switch self {
      case .b, .c, .a where isTrue:
          break
      }
      """
    testFormatting(
      for: input,
      rule: .sortSwitchCases,
      exclude: [.wrapSwitchCases])
  }

  @Test func sortedSwitchWhereConditionLastCase() {
    let input = """
      switch self {
      case .b, .c where isTrue, .a:
          break
      }
      """
    let output = """
      switch self {
      case .a, .b, .c where isTrue:
          break
      }
      """
    testFormatting(
      for: input, output, rule: .sortSwitchCases,
      exclude: [.wrapSwitchCases])
  }

  @Test func sortNumericSwitchCases() {
    let input = """
      switch foo {
      case 12, 3, 5, 7, 8, 10, 1:
          break
      }
      """
    let output = """
      switch foo {
      case 1, 3, 5, 7, 8, 10, 12:
          break
      }
      """
    testFormatting(
      for: input, output, rule: .sortSwitchCases,
      exclude: [.wrapSwitchCases])
  }

  @Test func sortedSwitchTuples() {
    let input = """
      switch foo {
      case (.foo, _),
           (.bar, _),
           (.baz, _),
           (_, .foo):
      }
      """
    let output = """
      switch foo {
      case (_, .foo),
           (.bar, _),
           (.baz, _),
           (.foo, _):
      }
      """
    testFormatting(for: input, output, rule: .sortSwitchCases)
  }

  @Test func sortedSwitchTuples2() {
    let input = """
      switch self {
      case (.quux, .bar),
           (_, .foo),
           (_, .bar),
           (_, .baz),
           (.foo, .bar):
      }
      """
    let output = """
      switch self {
      case (_, .bar),
           (_, .baz),
           (_, .foo),
           (.foo, .bar),
           (.quux, .bar):
      }
      """
    testFormatting(for: input, output, rule: .sortSwitchCases)
  }

  @Test func sortSwitchCasesShortestFirst() {
    let input = """
      switch foo {
      case let .fooAndBar(baz, quux),
           let .foo(baz):
      }
      """
    let output = """
      switch foo {
      case let .foo(baz),
           let .fooAndBar(baz, quux):
      }
      """
    testFormatting(for: input, output, rule: .sortSwitchCases)
  }

  @Test func sortHexLiteralCasesInAscendingOrder() {
    let input = """
      switch value {
      case 0x30 ... 0x39, // 0-9
           0x0300 ... 0x036F,
           0x1DC0 ... 0x1DFF,
           0x20D0 ... 0x20FF,
           0xFE20 ... 0xFE2F:
          return true
      default:
          return false
      }
      """
    testFormatting(for: input, rule: .sortSwitchCases)
  }

  @Test func mixedOctalHexIntAndBinaryLiteralCasesInAscendingOrder() {
    let input = """
      switch value {
      case 0o3,
           0x20,
           110,
           0b1111110:
          return true
      default:
          return false
      }
      """
    testFormatting(for: input, rule: .sortSwitchCases)
  }

  @Test func sortSwitchCasesNoUnwrapReturn() {
    let input = """
      switch self {
      case .b, .a, .c, .e, .d:
          return nil
      }
      """
    let output = """
      switch self {
      case .a, .b, .c, .d, .e:
          return nil
      }
      """
    testFormatting(
      for: input, output, rule: .sortSwitchCases,
      exclude: [.wrapSwitchCases])
  }
}
