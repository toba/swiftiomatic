import Testing
@testable import Swiftiomatic

@Suite struct RedundantLetErrorTests {
    @Test func catchLetError() {
        let input = """
        do {} catch let error {}
        """
        let output = """
        do {} catch {}
        """
        testFormatting(for: input, output, rule: .redundantLetError)
    }

    @Test func catchLetErrorWithTypedThrows() {
        let input = """
        do throws(Foo) {} catch let error {}
        """
        let output = """
        do throws(Foo) {} catch {}
        """
        testFormatting(for: input, output, rule: .redundantLetError)
    }
}
