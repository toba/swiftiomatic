@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseAnyAppleOSAvailabilityTests: RuleTesting {
  private static let message =
    "five platform clauses have to be kept in sync by hand — collapse them to '@available(anyAppleOS …, *)'"

  @Test func fivePlatformsCollapsed() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        1️⃣@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
        func newAPI() {}
        """,
      expected: """
        @available(anyAppleOS 26.0, *)
        func newAPI() {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func majorOnlyVersionCollapsed() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        1️⃣@available(iOS 26, macOS 26, watchOS 26, tvOS 26, visionOS 26, *)
        func newAPI() {}
        """,
      expected: """
        @available(anyAppleOS 26, *)
        func newAPI() {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func patchVersionCollapsed() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        1️⃣@available(macOS 26.1.2, iOS 26.1.2, tvOS 26.1.2, watchOS 26.1.2, visionOS 26.1.2, *)
        func newAPI() {}
        """,
      expected: """
        @available(anyAppleOS 26.1.2, *)
        func newAPI() {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func partialPlatformListUntouched() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        @available(macOS 26.0, iOS 26.0, *)
        func newAPI() {}
        """,
      expected: """
        @available(macOS 26.0, iOS 26.0, *)
        func newAPI() {}
        """,
      findings: []
    )
  }

  @Test func mismatchedVersionsUntouched() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        @available(macOS 26.4, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
        func newAPI() {}
        """,
      expected: """
        @available(macOS 26.4, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
        func newAPI() {}
        """,
      findings: []
    )
  }

  @Test func deprecatedAttributeUntouched() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        @available(macOS, deprecated: 27.0, message: "gone")
        func oldAPI() {}
        """,
      expected: """
        @available(macOS, deprecated: 27.0, message: "gone")
        func oldAPI() {}
        """,
      findings: []
    )
  }

  @Test func unconditionalUnavailableUntouched() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        @available(*, unavailable)
        func gone() {}
        """,
      expected: """
        @available(*, unavailable)
        func gone() {}
        """,
      findings: []
    )
  }

  @Test func missingWildcardUntouched() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0)
        func newAPI() {}
        """,
      expected: """
        @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0)
        func newAPI() {}
        """,
      findings: []
    )
  }

  @Test func alreadyAnyAppleOSUntouched() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        @available(anyAppleOS 26.0, *)
        func newAPI() {}
        """,
      expected: """
        @available(anyAppleOS 26.0, *)
        func newAPI() {}
        """,
      findings: []
    )
  }

  @Test func otherAttributeUntouched() {
    assertFormatting(
      UseAnyAppleOSAvailability.self,
      input: """
        @objc
        class Foo {}
        """,
      expected: """
        @objc
        class Foo {}
        """,
      findings: []
    )
  }
}
