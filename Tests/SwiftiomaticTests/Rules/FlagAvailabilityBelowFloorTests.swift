@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
package import Testing

@Suite
struct FlagAvailabilityBelowFloorTests: RuleTesting {
  private static let attributeMessage =
    "remove '@available'; every version it names is at or below the deployment floor"
  private static let availableMessage =
    "remove '#available'; every version it names is at or below the deployment floor, so the check is always true"
  private static let unavailableMessage =
    "'#unavailable' names only versions at or below the deployment floor, so the check is always false"

  private func config(
    macOS: String? = "14",
    iOS: String? = "17",
    tvOS: String? = nil,
    watchOS: String? = nil,
    visionOS: String? = nil
  ) -> Configuration {
    var c = Configuration.forTesting(enabledRule: FlagAvailabilityBelowFloor.self.key)
    c[FlagAvailabilityBelowFloor.self].macOS = macOS
    c[FlagAvailabilityBelowFloor.self].iOS = iOS
    c[FlagAvailabilityBelowFloor.self].tvOS = tvOS
    c[FlagAvailabilityBelowFloor.self].watchOS = watchOS
    c[FlagAvailabilityBelowFloor.self].visionOS = visionOS
    return c
  }

  // MARK: - @available

  @Test func attributeBelowFloorRemovedKeepingDocComment() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        struct S {
          /// Does a thing.
          1️⃣@available(macOS 13, *)
          func run() {}
        }
        """,
      expected: """
        struct S {
          /// Does a thing.
          func run() {}
        }
        """,
      findings: [FindingSpec("1️⃣", message: Self.attributeMessage)],
      configuration: config())
  }

  @Test func attributeAtFloorWithSeveralPlatformsRemoved() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        1️⃣@available(macOS 14.0, iOS 16.4, *)
        public final class A {}
        """,
      expected: """
        public final class A {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.attributeMessage)],
      configuration: config())
  }

  @Test func attributeAmongOtherAttributesRemoved() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        @MainActor 1️⃣@available(iOS 15, *) struct A {}

        2️⃣@available(macOS 12, *)
        @MainActor
        var b: Int { 0 }

        @MainActor
        3️⃣@available(macOS 12, *)
        enum C {}
        """,
      expected: """
        @MainActor struct A {}

        @MainActor
        var b: Int { 0 }

        @MainActor
        enum C {}
        """,
      findings: [
        FindingSpec("1️⃣", message: Self.attributeMessage),
        FindingSpec("2️⃣", message: Self.attributeMessage),
        FindingSpec("3️⃣", message: Self.attributeMessage),
      ],
      configuration: config())
  }

  @Test func attributeOnInitializerAndExtensionRemoved() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        1️⃣@available(macOS 11, *)
        extension A {
          2️⃣@available(macOS 11, *)
          public init() {}
        }
        """,
      expected: """
        extension A {
          public init() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: Self.attributeMessage),
        FindingSpec("2️⃣", message: Self.attributeMessage),
      ],
      configuration: config())
  }

  @Test func introducedLabelFormRemoved() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        1️⃣@available(macOS, introduced: 12)
        func run() {}
        """,
      expected: """
        func run() {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.attributeMessage)],
      configuration: config())
  }

  @Test func anyAppleOSBelowEveryConfiguredFloorRemoved() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        1️⃣@available(anyAppleOS 26, *)
        func run() {}
        """,
      expected: """
        func run() {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.attributeMessage)],
      configuration: config(macOS: "26", iOS: "26.1"))
  }

  @Test func anyAppleOSAboveOneConfiguredFloorUnchanged() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        @available(anyAppleOS 26, *)
        func run() {}
        """,
      expected: """
        @available(anyAppleOS 26, *)
        func run() {}
        """,
      configuration: config(macOS: "26", iOS: "18"))
  }

  @Test func attributeNearMissesUnchanged() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        @available(macOS 15, *)
        func above() {}
        @available(macOS 13, tvOS 16, *)
        func unconfiguredPlatform() {}
        @available(*, deprecated, message: "old")
        func deprecated() {}
        @available(macOS, deprecated: 12)
        func deprecatedOnPlatform() {}
        @available(macOS, introduced: 10.15, deprecated: 12)
        func introducedAndDeprecated() {}
        @available(macOS, introduced: 10.15, obsoleted: 12)
        func introducedAndObsoleted() {}
        @available(*, unavailable)
        func unavailable() {}
        @available(macOS, unavailable)
        func unavailableOnPlatform() {}
        @available(*, renamed: "other")
        func renamed() {}
        @available(swift 5)
        func swiftVersion() {}
        @available(macOSApplicationExtension 10.15, *)
        func appExtension() {}
        """,
      expected: """
        @available(macOS 15, *)
        func above() {}
        @available(macOS 13, tvOS 16, *)
        func unconfiguredPlatform() {}
        @available(*, deprecated, message: "old")
        func deprecated() {}
        @available(macOS, deprecated: 12)
        func deprecatedOnPlatform() {}
        @available(macOS, introduced: 10.15, deprecated: 12)
        func introducedAndDeprecated() {}
        @available(macOS, introduced: 10.15, obsoleted: 12)
        func introducedAndObsoleted() {}
        @available(*, unavailable)
        func unavailable() {}
        @available(macOS, unavailable)
        func unavailableOnPlatform() {}
        @available(*, renamed: "other")
        func renamed() {}
        @available(swift 5)
        func swiftVersion() {}
        @available(macOSApplicationExtension 10.15, *)
        func appExtension() {}
        """,
      configuration: config())
  }

  @Test func noFloorConfiguredDoesNothing() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        @available(macOS 10.15, *)
        func run() {
          if #available(macOS 10.15, *) {
            go()
          }
        }
        """,
      expected: """
        @available(macOS 10.15, *)
        func run() {
          if #available(macOS 10.15, *) {
            go()
          }
        }
        """,
      configuration: config(macOS: nil, iOS: ""))
  }

  // MARK: - #available

  @Test func soleIfConditionUnwrapsBodyAndDropsElse() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        func run() {
          start()
          // Prefer the new API.
          if 1️⃣#available(macOS 13, iOS 16, *) {
            first()
            if ready {
              second()
            }
          } else {
            fallback()
          }
          finish()
        }
        """,
      expected: """
        func run() {
          start()
          // Prefer the new API.
          first()
          if ready {
            second()
          }
          finish()
        }
        """,
      findings: [FindingSpec("1️⃣", message: Self.availableMessage)],
      configuration: config())
  }

  @Test func soleIfConditionWithEmptyBodyRemoved() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        func run() {
          if 1️⃣#available(macOS 13, *) {}
          finish()
        }
        """,
      expected: """
        func run() {
          finish()
        }
        """,
      findings: [FindingSpec("1️⃣", message: Self.availableMessage)],
      configuration: config())
  }

  @Test func soleGuardConditionRemoved() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        func run() {
          guard 1️⃣#available(macOS 13, *) else { return }
          finish()
        }
        """,
      expected: """
        func run() {
          finish()
        }
        """,
      findings: [FindingSpec("1️⃣", message: Self.availableMessage)],
      configuration: config())
  }

  @Test func oneConditionAmongSeveralRemoved() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        func run() {
          if 1️⃣#available(macOS 13, *), let value = input {
            use(value)
          }
          guard let value = input, 2️⃣#available(iOS 16, *) else { return }
          while ready, 3️⃣#available(macOS 12, *), !done {
            step()
          }
        }
        """,
      expected: """
        func run() {
          if let value = input {
            use(value)
          }
          guard let value = input else { return }
          while ready, !done {
            step()
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: Self.availableMessage),
        FindingSpec("2️⃣", message: Self.availableMessage),
        FindingSpec("3️⃣", message: Self.availableMessage),
      ],
      configuration: config())
  }

  @Test func bodyWithDeferIsFlaggedButKept() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        func run() {
          if 1️⃣#available(macOS 13, *) {
            defer { stop() }
            go()
          }
        }
        """,
      expected: """
        func run() {
          if #available(macOS 13, *) {
            defer { stop() }
            go()
          }
        }
        """,
      findings: [FindingSpec("1️⃣", message: Self.availableMessage)],
      configuration: config())
  }

  @Test func unavailableIsLintOnly() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        func run() {
          if 1️⃣#unavailable(macOS 13) {
            fallback()
          }
        }
        """,
      expected: """
        func run() {
          if #unavailable(macOS 13) {
            fallback()
          }
        }
        """,
      findings: [FindingSpec("1️⃣", message: Self.unavailableMessage)],
      configuration: config())
  }

  @Test func availabilityConditionNearMissesUnchanged() {
    assertFormatting(
      FlagAvailabilityBelowFloor.self,
      input: """
        func run() {
          if #available(macOS 15, *) {
            go()
          }
          if #available(macOS 13, tvOS 16, *) {
            go()
          }
          guard #available(iOS 18, *) else { return }
          if #unavailable(macOS 15) {
            fallback()
          }
        }
        """,
      expected: """
        func run() {
          if #available(macOS 15, *) {
            go()
          }
          if #available(macOS 13, tvOS 16, *) {
            go()
          }
          guard #available(iOS 18, *) else { return }
          if #unavailable(macOS 15) {
            fallback()
          }
        }
        """,
      configuration: config())
  }

  @Test func lintDefaultsWarnAndRewriteOn() {
    #expect(FlagAvailabilityBelowFloor.defaultValue.lint == .warn)
    #expect(FlagAvailabilityBelowFloor.defaultValue.rewrite)
    #expect(FlagAvailabilityBelowFloor.defaultValue.macOS == nil)
  }
}
