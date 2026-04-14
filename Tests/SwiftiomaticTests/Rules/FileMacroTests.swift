@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct FileMacroTests: RuleTesting {

  @Test func fileReplacedWithFileID() {
    assertFormatting(
      FileMacro.self,
      input: """
        let path = 1️⃣#file
        """,
      expected: """
        let path = #fileID
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '#file' with '#fileID'; they are equivalent in Swift 6+"),
      ]
    )
  }

  @Test func fileIDUnchanged() {
    assertFormatting(
      FileMacro.self,
      input: """
        let path = #fileID
        """,
      expected: """
        let path = #fileID
        """,
      findings: []
    )
  }

  @Test func filePathUnchanged() {
    assertFormatting(
      FileMacro.self,
      input: """
        let path = #filePath
        """,
      expected: """
        let path = #filePath
        """,
      findings: []
    )
  }

  @Test func fileInFunctionArgument() {
    assertFormatting(
      FileMacro.self,
      input: """
        print(1️⃣#file)
        """,
      expected: """
        print(#fileID)
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '#file' with '#fileID'; they are equivalent in Swift 6+"),
      ]
    )
  }

  @Test func fileInDefaultArgument() {
    assertFormatting(
      FileMacro.self,
      input: """
        func log(file: String = 1️⃣#file) {}
        """,
      expected: """
        func log(file: String = #fileID) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '#file' with '#fileID'; they are equivalent in Swift 6+"),
      ]
    )
  }

  @Test func unrelatedMacroUnchanged() {
    assertFormatting(
      FileMacro.self,
      input: """
        let x = #line
        let y = #function
        """,
      expected: """
        let x = #line
        let y = #function
        """,
      findings: []
    )
  }
}
