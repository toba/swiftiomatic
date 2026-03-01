import Testing

@testable import Swiftiomatic

@Suite struct WrapSwitchCasesTests {
  @Test func multilineSwitchCases() {
    let input = """
      func foo() {
          switch bar {
          case .a(_), .b, "c":
              print("")
          case .d:
              print("")
          }
      }
      """
    let output = """
      func foo() {
          switch bar {
          case .a(_),
               .b,
               "c":
              print("")
          case .d:
              print("")
          }
      }
      """
    testFormatting(for: input, output, rule: .wrapSwitchCases)
  }

  @Test func ifAfterSwitchCaseNotWrapped() {
    let input = """
      switch foo {
      case "foo":
          print("")
      default:
          print("")
      }
      if let foo = bar, foo != .baz {
          throw error
      }
      """
    testFormatting(for: input, rule: .wrapSwitchCases)
  }
}
