@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropUnusedControlFlowLabelTests: RuleTesting {
  @Test func unusedLabelOnWhile() {
    assertLint(
      DropUnusedControlFlowLabel.self,
      """
      1️⃣loop: while true { break }
      """,
      findings: [
        FindingSpec("1️⃣", message: "control flow label 'loop' is never referenced — remove it"),
      ]
    )
  }

  @Test func unusedLabelOnFor() {
    assertLint(
      DropUnusedControlFlowLabel.self,
      """
      1️⃣loop: for x in array { break }
      """,
      findings: [
        FindingSpec("1️⃣", message: "control flow label 'loop' is never referenced — remove it"),
      ]
    )
  }

  @Test func unusedLabelOnSwitch() {
    assertLint(
      DropUnusedControlFlowLabel.self,
      """
      1️⃣label: switch number {
      case 1: print("1")
      case 2: print("2")
      default: break
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "control flow label 'label' is never referenced — remove it"),
      ]
    )
  }

  @Test func wrongLabelStillFlagsOuter() {
    assertLint(
      DropUnusedControlFlowLabel.self,
      """
      1️⃣loop: while true { break loop1 }
      """,
      findings: [
        FindingSpec("1️⃣", message: "control flow label 'loop' is never referenced — remove it"),
      ]
    )
  }

  @Test func usedBreakLabelDoesNotTrigger() {
    assertLint(
      DropUnusedControlFlowLabel.self,
      """
      loop: while true { break loop }
      """,
      findings: []
    )
  }

  @Test func usedContinueLabelDoesNotTrigger() {
    assertLint(
      DropUnusedControlFlowLabel.self,
      """
      loop: while true { continue loop }
      """,
      findings: []
    )
  }

  @Test func unlabeledLoopDoesNotTrigger() {
    assertLint(
      DropUnusedControlFlowLabel.self,
      """
      while true { break }
      """,
      findings: []
    )
  }

  @Test func usedLabelInRepeat() {
    assertLint(
      DropUnusedControlFlowLabel.self,
      """
      loop: repeat {
        if x == 10 {
          break loop
        }
      } while true
      """,
      findings: []
    )
  }
}
