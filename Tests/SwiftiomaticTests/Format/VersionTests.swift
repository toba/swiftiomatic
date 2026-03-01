import Testing

@testable import Swiftiomatic

@Suite struct VersionTests {
  // MARK: Version parsing

  @Test func parseEmptyVersion() {
    let version = Version(rawValue: "")
    #expect(version == nil)
  }

  @Test func parseOrdinaryVersion() {
    let version = Version(rawValue: "4.2")
    #expect(version == "4.2")
  }

  @Test func parsePaddedVersion() {
    let version = Version(rawValue: " 4.2 ")
    #expect(version == "4.2")
  }

  @Test func parseThreePartVersion() {
    let version = Version(rawValue: "3.1.5")
    #expect(version != nil)
    #expect(version == "3.1.5")
  }

  @Test func parsePreviewVersion() {
    let version = Version(rawValue: "3.0-PREVIEW-4")
    #expect(version != nil)
    #expect(version == "3.0-PREVIEW-4")
  }

  @Test func comparison() {
    let version = Version(rawValue: "3.1.5")
    #expect(version ?? "0" < "3.2")
    #expect(version ?? "0" > "3.1.4")
  }

  @Test func previewComparison() {
    let version = Version(rawValue: "3.0-PREVIEW-4")
    #expect(version ?? "0" < "4.0")
    #expect(version ?? "0" > "2.0")
  }

  @Test func wildcardVersion() {
    let version = Version(rawValue: "3.x")
    #expect(version != nil)
    #expect(version ?? "0" < "4.0")
    #expect(version ?? "0" > "2.0")
  }
}
