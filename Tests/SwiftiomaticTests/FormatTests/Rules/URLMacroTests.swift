import Testing

@testable import Swiftiomatic

@Suite struct URLMacroTests {
  @Test func basicURLStringForceUnwrapConverted() {
    let input = """
      let url = URL(string: "https://example.com")!
      """
    let output = """
      import URLFoundation

      let url = #URL("https://example.com")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func importNotAddedInFragment() {
    let input = """
      let url = URL(string: "https://example.com")!
      """
    let output = """
      let url = #URL("https://example.com")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"), fragment: true)
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLStringForceUnwrapInReturnStatement() {
    let input = """
      func getURL() -> URL {
          return URL(string: "https://api.example.com/users")!
      }
      """
    let output = """
      import URLFoundation

      func getURL() -> URL {
          return #URL("https://api.example.com/users")
      }
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLStringForceUnwrapInAssignment() {
    let input = """
      var baseURL: URL
      baseURL = URL(string: "https://api.service.com")!
      """
    let output = """
      import URLFoundation

      var baseURL: URL
      baseURL = #URL("https://api.service.com")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLStringForceUnwrapWithComplexString() {
    let input = """
      let complexURL = URL(string: "https://example.com/path?param=value&other=123")!
      """
    let output = """
      import URLFoundation

      let complexURL = #URL("https://example.com/path?param=value&other=123")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLStringForceUnwrapWithSpacing() {
    let input = """
      let url = URL(string: "https://example.com" )!
      """
    let output = """
      import URLFoundation

      let url = #URL("https://example.com" )
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(
      for: input, output, rule: .urlMacro, options: options,
      exclude: [.propertyTypes, .spaceInsideParens])
  }

  @Test func multipleURLStringForceUnwraps() {
    let input = """
      let url1 = URL(string: "https://example.com")!
      let url2 = URL(string: "https://other.com")!
      """
    let output = """
      import URLFoundation

      let url1 = #URL("https://example.com")
      let url2 = #URL("https://other.com")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLStringOptionalNotConverted() {
    let input = """
      let url = URL(string: "https://example.com")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLStringOptionalWithNilCoalescingNotConverted() {
    let input = """
      let url = URL(string: "https://example.com") ?? URL(fileURLWithPath: "/")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLFileURLWithPathNotConverted() {
    let input = """
      let url = URL(fileURLWithPath: "/path/to/file")!
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLWithOtherInitializerNotConverted() {
    let input = """
      let url = URL(string: "https://example.com", relativeTo: baseURL)!
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func existingURLFoundationImportNotDuplicated() {
    let input = """
      import URLFoundation

      let url = URL(string: "https://example.com")!
      """
    let output = """
      import URLFoundation

      let url = #URL("https://example.com")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLInDifferentContexts() {
    let input = """
      class NetworkService {
          private let baseURL = URL(string: "https://api.example.com")!

          func makeRequest() {
              let url = URL(string: "https://api.example.com/endpoint")!
              // Use url...
          }
      }
      """
    let output = """
      import URLFoundation

      class NetworkService {
          private let baseURL = #URL("https://api.example.com")

          func makeRequest() {
              let url = #URL("https://api.example.com/endpoint")
              // Use url...
          }
      }
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func uRLWithEscapedCharacters() {
    let input = """
      let url = URL(string: "https://example.com/path with spaces")!
      """
    let output = """
      import URLFoundation

      let url = #URL("https://example.com/path with spaces")
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func noTransformationWhenMacroNotConfigured() {
    let input = """
      let url = URL(string: "https://example.com")!
      """
    testFormatting(for: input, rule: .urlMacro, exclude: [.propertyTypes])
  }

  @Test func customMacroConfiguration() {
    let input = """
      let url = URL(string: "https://example.com")!
      """
    let output = """
      import CustomURLLib

      let url = #CustomURL("https://example.com")
      """
    let options = FormatOptions(urlMacro: .macro("#CustomURL", module: "CustomURLLib"))
    testFormatting(for: input, output, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func stringInterpolationNotConverted() {
    let input = """
      let domain = "example.com"
      let url = URL(string: "https://\\(domain)/path")!
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func stringConcatenationNotConverted() {
    let input = """
      let baseURL = "https://api.example.com"
      let url = URL(string: baseURL + "/endpoint")!
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }

  @Test func complexStringExpressionNotConverted() {
    let input = """
      let clientID = "12345"
      let url = URL(string: "com.googleusercontent.apps.\\(clientID):/oauth2redirect/google")!
      """
    let options = FormatOptions(urlMacro: .macro("#URL", module: "URLFoundation"))
    testFormatting(for: input, rule: .urlMacro, options: options, exclude: [.propertyTypes])
  }
}
