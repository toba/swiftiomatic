import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct SwitchCaseAlignmentRuleTests {
  // MARK: - Non-triggering (default: non-indented cases)

  @Test func alignedCasesDoNotTrigger() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      """
      switch someBool {
      case true: // case 1
          print('red')
      case false:
          /*
          case 2
          */
          if case let .someEnum(val) = someFunc() {
              print('blue')
          }
      }
      enum SomeEnum {
          case innocent
      }
      """)
  }

  @Test func nestedSwitchAlignedDoesNotTrigger() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      """
      if aBool {
          switch someBool {
          case true:
              print('red')
          case false:
              print('blue')
          }
      }
      """)
  }

  @Test func switchWithCommentsAlignedDoesNotTrigger() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      """
      switch someInt {
      // comments ignored
      case 0:
          // zero case
          print('Zero')
      case 1:
          print('One')
      default:
          print('Some other number')
      }
      """)
  }

  @Test func switchExpressionAlignedDoesNotTrigger() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      """
      func f() -> Int {
          return switch i {
          case 1: 1
          default: 2
          }
      }
      """)
  }

  @Test func oneLinerDoesNotTriggerWhenIgnored() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      "switch i { case .x: 1 default: 0 }",
      configuration: ["ignore_one_liners": true])
  }

  @Test func letOneLinerDoesNotTriggerWhenIgnored() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      "let a = switch i { case .x: 1 default: 0 }",
      configuration: ["ignore_one_liners": true])
  }

  // MARK: - Triggering (default: non-indented cases)

  @Test func misalignedCasesTrigger() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      switch someBool {
      case true:
          print('red')
          1️⃣case false:
              print('blue')
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func indentedCasesInNonIndentedModeTrigger() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      switch someBool {
          1️⃣case true:
              print("red")
          2️⃣case false:
              print("blue")
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  @Test func misalignedDefaultTriggers() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      let a = switch i {
      case 1: 1
          1️⃣default: 2
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func oneLinerTriggersWithDefaultConfig() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      "switch i { 1️⃣case .x: 1 2️⃣default: 0 }",
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  @Test func oneLinerWithOpenBraceOnNewLineTriggersWhenIgnored() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      switch i
      { 1️⃣case .x: 1 2️⃣default: 0 }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: ["ignore_one_liners": true])
  }

  @Test func partialOneLinerTriggersWhenIgnored() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      switch i {
      1️⃣case .x: 1 2️⃣default: 0 }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: ["ignore_one_liners": true])
  }

  @Test func partialOneLinerClosingOnNewLineTriggersWhenIgnored() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      switch i { 1️⃣case .x: 1 2️⃣default: 0
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: ["ignore_one_liners": true])
  }

  @Test func letSwitchMixedAlignmentTriggersWhenIgnored() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      let a = switch i {
      case .x: 1 1️⃣default: 0
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["ignore_one_liners": true])
  }

  @Test func letSwitchPartialOneLinerTriggersWhenIgnored() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      let a = switch i {
      1️⃣case .x: 1 2️⃣default: 0 }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: ["ignore_one_liners": true])
  }

  // MARK: - Indented cases configuration

  @Test func indentedCasesAlignedDoNotTrigger() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      """
      switch someBool {
          case true:
              print("red")
          case false:
              print("blue")
      }
      """,
      configuration: ["indented_cases": true])
  }

  @Test func nestedIndentedCasesDoNotTrigger() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      """
      if aBool {
          switch someBool {
              case true:
                  print('red')
              case false:
                  print('blue')
          }
      }
      """,
      configuration: ["indented_cases": true])
  }

  @Test func indentedSwitchExpressionDoesNotTrigger() async {
    await assertNoViolation(
      SwitchCaseAlignmentRule.self,
      """
      let a = switch i {
          case 1: 1
          default: 2
      }
      """,
      configuration: ["indented_cases": true])
  }

  @Test func nonIndentedCasesInIndentedModeTrigger() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      switch someBool {
      1️⃣case true: // case 1
          print('red')
      2️⃣case false:
          if case let .someEnum(val) = someFunc() {
              print('blue')
          }
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: ["indented_cases": true])
  }

  @Test func misalignedCasesInIndentedModeTrigger() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      switch someBool {
          case true:
              print('red')
              1️⃣case false:
                  print('blue')
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["indented_cases": true])
  }

  @Test func indentedDefaultMisalignedTriggers() async {
    await assertLint(
      SwitchCaseAlignmentRule.self,
      """
      let a = switch i {
          case 1: 1
              1️⃣default: 2
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["indented_cases": true])
  }
}
