@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct AcronymsTests: RuleTesting {
  @Test func titlecasedUrl() {
    assertFormatting(
      Acronyms.self,
      input: """
        let 1️⃣destinationUrl: String = ""
        """,
      expected: """
        let destinationURL: String = ""
        """,
      findings: [
        FindingSpec("1️⃣", message: "capitalize acronyms in identifier"),
      ]
    )
  }

  @Test func titlecasedJson() {
    assertFormatting(
      Acronyms.self,
      input: """
        struct 1️⃣JsonParser {}
        """,
      expected: """
        struct JSONParser {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "capitalize acronyms in identifier"),
      ]
    )
  }

  @Test func alreadyUppercased() {
    assertFormatting(
      Acronyms.self,
      input: """
        let destinationURL: String = ""
        """,
      expected: """
        let destinationURL: String = ""
        """,
      findings: []
    )
  }

  @Test func lowercaseNotModified() {
    assertFormatting(
      Acronyms.self,
      input: """
        let urlRouter = foo()
        """,
      expected: """
        let urlRouter = foo()
        """,
      findings: []
    )
  }

  @Test func pluralAcronym() {
    assertFormatting(
      Acronyms.self,
      input: """
        let 1️⃣screenIds: [String] = []
        """,
      expected: """
        let screenIDs: [String] = []
        """,
      findings: [
        FindingSpec("1️⃣", message: "capitalize acronyms in identifier"),
      ]
    )
  }

  @Test func functionName() {
    assertFormatting(
      Acronyms.self,
      input: """
        func 1️⃣fetchJson() {}
        """,
      expected: """
        func fetchJSON() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "capitalize acronyms in identifier"),
      ]
    )
  }
}
