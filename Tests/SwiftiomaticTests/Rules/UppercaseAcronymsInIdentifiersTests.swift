@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct AcronymsTests: RuleTesting {
  @Test func titlecasedUrl() {
    assertFormatting(
      UppercaseAcronymsInIdentifiers.self,
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
      UppercaseAcronymsInIdentifiers.self,
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
      UppercaseAcronymsInIdentifiers.self,
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
      UppercaseAcronymsInIdentifiers.self,
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
      UppercaseAcronymsInIdentifiers.self,
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
      UppercaseAcronymsInIdentifiers.self,
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

  // MARK: - Adapted from SwiftFormat reference tests

  @Test func idAtEndOfIdentifier() {
    assertFormatting(
      UppercaseAcronymsInIdentifiers.self,
      input: """
        let 1️⃣screenId = "screenId"
        """,
      expected: """
        let screenID = "screenId"
        """,
      findings: [
        FindingSpec("1️⃣", message: "capitalize acronyms in identifier"),
      ]
    )
  }

  @Test func acronymEdgeCaseNotModified() {
    // "Url" followed by lowercase — not a boundary
    assertFormatting(
      UppercaseAcronymsInIdentifiers.self,
      input: """
        let validUrlschemes: Set<URL>
        """,
      expected: """
        let validUrlschemes: Set<URL>
        """,
      findings: []
    )
  }

  @Test func structNameWithInteriorAcronym() {
    assertFormatting(
      UppercaseAcronymsInIdentifiers.self,
      input: """
        struct 1️⃣UrlRouter {}
        """,
      expected: """
        struct URLRouter {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "capitalize acronyms in identifier"),
      ]
    )
  }

  @Test func multipleIdentifiersInOneFile() {
    assertFormatting(
      UppercaseAcronymsInIdentifiers.self,
      input: """
        let url: URL
        let 1️⃣destinationUrl: URL
        let id: ID
        let 2️⃣validUrls: Set<URL>
        """,
      expected: """
        let url: URL
        let destinationURL: URL
        let id: ID
        let validURLs: Set<URL>
        """,
      findings: [
        FindingSpec("1️⃣", message: "capitalize acronyms in identifier"),
        FindingSpec("2️⃣", message: "capitalize acronyms in identifier"),
      ]
    )
  }

  @Test func alreadyUppercasedAcronymNotModified() {
    assertFormatting(
      UppercaseAcronymsInIdentifiers.self,
      input: """
        var personIDs: [String]
        var ids: [UUID]
        """,
      expected: """
        var personIDs: [String]
        var ids: [UUID]
        """,
      findings: []
    )
  }

  @Test func pluralIdAcronym() {
    assertFormatting(
      UppercaseAcronymsInIdentifiers.self,
      input: """
        var 1️⃣userIds: [Int]
        """,
      expected: """
        var userIDs: [Int]
        """,
      findings: [
        FindingSpec("1️⃣", message: "capitalize acronyms in identifier"),
      ]
    )
  }

  @Test func uniqueIdentifierNotModified() {
    // "unique" contains "u" but "uniqueIdentifier" doesn't have a titlecased acronym
    assertFormatting(
      UppercaseAcronymsInIdentifiers.self,
      input: """
        let uniqueIdentifier = UUID()
        """,
      expected: """
        let uniqueIdentifier = UUID()
        """,
      findings: []
    )
  }
}
