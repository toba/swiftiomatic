@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct SortDeclarationsTests: RuleTesting {

  @Test func sortEnumCasesBetweenMarkers() {
    assertFormatting(
      SortDeclarations.self,
      input: """
        enum FeatureFlags {
          // swiftiomatic:sort:begin
          1️⃣case upsellB
          case fooFeature
          case barFeature
          case upsellA
          // swiftiomatic:sort:end

          var anUnsortedProperty: Foo {
            Foo()
          }
        }
        """,
      expected: """
        enum FeatureFlags {
          // swiftiomatic:sort:begin
          case barFeature
          case fooFeature
          case upsellA
          case upsellB
          // swiftiomatic:sort:end

          var anUnsortedProperty: Foo {
            Foo()
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort declarations alphabetically"),
      ]
    )
  }

  @Test func alreadySorted() {
    assertFormatting(
      SortDeclarations.self,
      input: """
        enum FeatureFlags {
          // swiftiomatic:sort:begin
          case barFeature
          case fooFeature
          case upsellA
          case upsellB
          // swiftiomatic:sort:end
        }
        """,
      expected: """
        enum FeatureFlags {
          // swiftiomatic:sort:begin
          case barFeature
          case fooFeature
          case upsellA
          case upsellB
          // swiftiomatic:sort:end
        }
        """,
      findings: []
    )
  }

  @Test func noMarkers() {
    assertFormatting(
      SortDeclarations.self,
      input: """
        enum FeatureFlags {
          case upsellB
          case fooFeature
          case barFeature
          case upsellA
        }
        """,
      expected: """
        enum FeatureFlags {
          case upsellB
          case fooFeature
          case barFeature
          case upsellA
        }
        """,
      findings: []
    )
  }

  @Test func sortTopLevelDeclarations() {
    assertFormatting(
      SortDeclarations.self,
      input: """
        let anUnsortedGlobal = 0

        // swiftiomatic:sort:begin
        1️⃣let sortThisGlobal = 1
        public let thisGlobalIsSorted = 2
        private let anotherSortedGlobal = 5
        let sortAllOfThem = 8
        // swiftiomatic:sort:end

        let anotherUnsortedGlobal = 9
        """,
      expected: """
        let anUnsortedGlobal = 0

        // swiftiomatic:sort:begin
        private let anotherSortedGlobal = 5
        let sortAllOfThem = 8
        let sortThisGlobal = 1
        public let thisGlobalIsSorted = 2
        // swiftiomatic:sort:end

        let anotherUnsortedGlobal = 9
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort declarations alphabetically"),
      ]
    )
  }

  @Test func singleItemNotSorted() {
    assertFormatting(
      SortDeclarations.self,
      input: """
        enum Flags {
          // swiftiomatic:sort:begin
          case onlyOne
          // swiftiomatic:sort:end
        }
        """,
      expected: """
        enum Flags {
          // swiftiomatic:sort:begin
          case onlyOne
          // swiftiomatic:sort:end
        }
        """,
      findings: []
    )
  }

  @Test func sortUsesLocalizedCompare() {
    assertFormatting(
      SortDeclarations.self,
      input: """
        enum Flags {
          // swiftiomatic:sort:begin
          case upsella
          case upsellA
          case upsellb
          case upsellB
          // swiftiomatic:sort:end
        }
        """,
      expected: """
        enum Flags {
          // swiftiomatic:sort:begin
          case upsella
          case upsellA
          case upsellb
          case upsellB
          // swiftiomatic:sort:end
        }
        """,
      findings: []
    )
  }
}
