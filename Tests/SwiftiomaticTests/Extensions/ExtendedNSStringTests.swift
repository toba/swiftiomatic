import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct ExtendedNSStringTests {
  @Test func lineAndCharacterForByteOffset_forContentsContainingMultibyteCharacters() {
    let contents =
      "" + "import Foundation\n"  // 18 characters
      + "class Test {\n"  // 13 characters
      + "func test() {\n"  // 14 characters
      + "// \u{65E5}\u{672C}\u{8A9E}\u{30B3}\u{30E1}\u{30F3}\u{30C8} : comment in Japanese\n"  // 33 characters
      + "// do something\n"  // 16 characters
      + "}\n" + "}"
    // A character placed on 80 offset indicates a white-space before 'do' at 5th line.
    if let lineAndCharacter = StringView(contents).lineAndCharacter(forCharacterOffset: 80) {
      #expect(lineAndCharacter.line == 5)
      #expect(lineAndCharacter.character == 3)
    } else {
      Issue.record("NSString.lineAndCharacterForByteOffset should return non-nil tuple.")
    }
  }
}
