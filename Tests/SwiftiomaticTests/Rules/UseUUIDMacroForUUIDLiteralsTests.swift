@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseUUIDMacroForUUIDLiteralsTests: RuleTesting {
  private static let message = "replace force-unwrapped 'UUID(uuidString:)' with UUID macro"

  private func config(
    macroName: String = "#UUID",
    moduleName: String = "UUIDFoundation"
  ) -> Configuration {
    var c = Configuration.forTesting(enabledRule: UseUUIDMacroForUUIDLiterals.self.key)
    c[UseUUIDMacroForUUIDLiterals.self].macroName = macroName
    c[UseUUIDMacroForUUIDLiterals.self].moduleName = moduleName
    return c
  }

  @Test func basicConversionAddsImport() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        let id = 1️⃣UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        """,
      expected: """
        import UUIDFoundation

        let id = #UUID("E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)],
      configuration: config())
  }

  @Test func multipleConversionsAddOneImport() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        struct Fixtures {
          static let a = 1️⃣UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!

          func b() -> UUID {
            return 2️⃣UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
          }
        }
        """,
      expected: """
        import UUIDFoundation

        struct Fixtures {
          static let a = #UUID("E621E1F8-C36C-495A-93FC-0C247A3E6E5F")

          func b() -> UUID {
            return #UUID("00000000-0000-0000-0000-000000000001")
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
      ],
      configuration: config())
  }

  @Test func existingImportNotDuplicated() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        import UUIDFoundation

        let id = 1️⃣UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        """,
      expected: """
        import UUIDFoundation

        let id = #UUID("E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)],
      configuration: config())
  }

  @Test func importAddedAfterExistingImports() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        import Foundation

        let id = 1️⃣UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        """,
      expected: """
        import Foundation
        import UUIDFoundation

        let id = #UUID("E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)],
      configuration: config())
  }

  @Test func customMacroNameWithoutPound() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        let id = 1️⃣UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        """,
      expected: """
        import IDKit

        let id = #StaticUUID("E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)],
      configuration: config(macroName: "StaticUUID", moduleName: "IDKit"))
  }

  @Test func optionalInitializerNotConverted() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        """,
      expected: """
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        """,
      configuration: config())
  }

  @Test func interpolatedStringNotConverted() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-\\(suffix)")!
        """,
      expected: """
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-\\(suffix)")!
        """,
      configuration: config())
  }

  @Test func variableArgumentNotConverted() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        let id = UUID(uuidString: text)!
        """,
      expected: """
        let id = UUID(uuidString: text)!
        """,
      configuration: config())
  }

  @Test func otherInitializersNotConverted() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        let a = UUID()
        let b = Foo(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        let c = UUID(string: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        """,
      expected: """
        let a = UUID()
        let b = Foo(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        let c = UUID(string: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        """,
      configuration: config())
  }

  @Test func alreadyMacroFormUnchanged() {
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        import UUIDFoundation

        let id = #UUID("E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        """,
      expected: """
        import UUIDFoundation

        let id = #UUID("E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        """,
      configuration: config())
  }

  @Test func noTransformationWhenMacroNotConfigured() {
    var c = Configuration.forTesting(enabledRule: UseUUIDMacroForUUIDLiterals.self.key)
    c[UseUUIDMacroForUUIDLiterals.self] = UUIDMacroConfiguration()
    assertFormatting(
      UseUUIDMacroForUUIDLiterals.self,
      input: """
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        """,
      expected: """
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        """,
      configuration: c)
  }

  @Test func offByDefault() {
    #expect(UseUUIDMacroForUUIDLiterals.defaultValue.lint == .no)
    #expect(UseUUIDMacroForUUIDLiterals.defaultValue.rewrite == false)
    #expect(UseUUIDMacroForUUIDLiterals.defaultValue.macroName == nil)
  }
}
