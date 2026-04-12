import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct ExtendedStringTests {
  @Test func countOccurrences() {
    #expect("aabbabaaba".countOccurrences(of: "a") == 6)
    #expect("".countOccurrences(of: "a") == 0)
    #expect("\n\n".countOccurrences(of: "\n") == 2)
  }
}
