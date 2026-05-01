@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseURLMacroForURLLiteralsTests: RuleTesting {

  private func config(
    macroName: String = "#URL",
    moduleName: String = "URLFoundation"
  ) -> Configuration {
    var c = Configuration.forTesting(enabledRule: UseURLMacroForURLLiterals.self.key)
    c[UseURLMacroForURLLiterals.self].macroName = macroName
    c[UseURLMacroForURLLiterals.self].moduleName = moduleName
    return c
  }

  // MARK: - Basic conversion

  @Test func basicURLStringForceUnwrapConverted() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url = 1️⃣URL(string: "https://example.com")!
        """,
      expected: """
        import URLFoundation

        let url = #URL("https://example.com")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro")
      ],
      configuration: config())
  }

  @Test func urlStringForceUnwrapInReturnStatement() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        func getURL() -> URL {
          return 1️⃣URL(string: "https://api.example.com/users")!
        }
        """,
      expected: """
        import URLFoundation

        func getURL() -> URL {
          return #URL("https://api.example.com/users")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro")
      ],
      configuration: config())
  }

  @Test func urlStringForceUnwrapInAssignment() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        var baseURL: URL
        baseURL = 1️⃣URL(string: "https://api.service.com")!
        """,
      expected: """
        import URLFoundation

        var baseURL: URL
        baseURL = #URL("https://api.service.com")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro")
      ],
      configuration: config())
  }

  @Test func urlStringForceUnwrapWithComplexString() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let complexURL = 1️⃣URL(string: "https://example.com/path?param=value&other=123")!
        """,
      expected: """
        import URLFoundation

        let complexURL = #URL("https://example.com/path?param=value&other=123")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro")
      ],
      configuration: config())
  }

  // MARK: - Multiple occurrences

  @Test func multipleURLStringForceUnwraps() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url1 = 1️⃣URL(string: "https://example.com")!
        let url2 = 2️⃣URL(string: "https://other.com")!
        """,
      expected: """
        import URLFoundation

        let url1 = #URL("https://example.com")
        let url2 = #URL("https://other.com")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro"),
        FindingSpec("2️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro"),
      ],
      configuration: config())
  }

  @Test func urlInDifferentContexts() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        class NetworkService {
          private let baseURL = 1️⃣URL(string: "https://api.example.com")!

          func makeRequest() {
            let url = 2️⃣URL(string: "https://api.example.com/endpoint")!
            // Use url...
          }
        }
        """,
      expected: """
        import URLFoundation

        class NetworkService {
          private let baseURL = #URL("https://api.example.com")

          func makeRequest() {
            let url = #URL("https://api.example.com/endpoint")
            // Use url...
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro"),
        FindingSpec("2️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro"),
      ],
      configuration: config())
  }

  // MARK: - Import handling

  @Test func existingModuleImportNotDuplicated() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        import URLFoundation

        let url = 1️⃣URL(string: "https://example.com")!
        """,
      expected: """
        import URLFoundation

        let url = #URL("https://example.com")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro")
      ],
      configuration: config())
  }

  @Test func importAddedAfterExistingImports() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        import Foundation

        let url = 1️⃣URL(string: "https://example.com")!
        """,
      expected: """
        import Foundation
        import URLFoundation

        let url = #URL("https://example.com")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro")
      ],
      configuration: config())
  }

  // MARK: - Not converted

  @Test func urlStringOptionalNotConverted() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url = URL(string: "https://example.com")
        """,
      expected: """
        let url = URL(string: "https://example.com")
        """,
      findings: [],
      configuration: config())
  }

  @Test func urlStringOptionalWithNilCoalescingNotConverted() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url = URL(string: "https://example.com") ?? URL(fileURLWithPath: "/")
        """,
      expected: """
        let url = URL(string: "https://example.com") ?? URL(fileURLWithPath: "/")
        """,
      findings: [],
      configuration: config())
  }

  @Test func urlFileURLWithPathNotConverted() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url = URL(fileURLWithPath: "/path/to/file")!
        """,
      expected: """
        let url = URL(fileURLWithPath: "/path/to/file")!
        """,
      findings: [],
      configuration: config())
  }

  @Test func urlWithRelativeToArgNotConverted() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url = URL(string: "https://example.com", relativeTo: baseURL)!
        """,
      expected: """
        let url = URL(string: "https://example.com", relativeTo: baseURL)!
        """,
      findings: [],
      configuration: config())
  }

  @Test func stringInterpolationNotConverted() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let domain = "example.com"
        let url = URL(string: "https://\\(domain)/path")!
        """,
      expected: """
        let domain = "example.com"
        let url = URL(string: "https://\\(domain)/path")!
        """,
      findings: [],
      configuration: config())
  }

  @Test func stringConcatenationNotConverted() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let baseURL = "https://api.example.com"
        let url = URL(string: baseURL + "/endpoint")!
        """,
      expected: """
        let baseURL = "https://api.example.com"
        let url = URL(string: baseURL + "/endpoint")!
        """,
      findings: [],
      configuration: config())
  }

  @Test func variableArgNotConverted() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let str = "https://example.com"
        let url = URL(string: str)!
        """,
      expected: """
        let str = "https://example.com"
        let url = URL(string: str)!
        """,
      findings: [],
      configuration: config())
  }

  // MARK: - Configuration

  @Test func noTransformationWhenMacroNotConfigured() {
    // Default config has no macro configured
    var c = Configuration.forTesting(enabledRule: UseURLMacroForURLLiterals.self.key)
    c[UseURLMacroForURLLiterals.self] = URLMacroConfiguration()
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url = URL(string: "https://example.com")!
        """,
      expected: """
        let url = URL(string: "https://example.com")!
        """,
      findings: [],
      configuration: c)
  }

  @Test func customMacroConfiguration() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url = 1️⃣URL(string: "https://example.com")!
        """,
      expected: """
        import CustomURLLib

        let url = #CustomURL("https://example.com")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro")
      ],
      configuration: config(macroName: "#CustomURL", moduleName: "CustomURLLib"))
  }

  @Test func urlWithEscapedCharacters() {
    assertFormatting(
      UseURLMacroForURLLiterals.self,
      input: """
        let url = 1️⃣URL(string: "https://example.com/path with spaces")!
        """,
      expected: """
        import URLFoundation

        let url = #URL("https://example.com/path with spaces")
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace force-unwrapped 'URL(string:)' with URL macro")
      ],
      configuration: config())
  }
}
