import Testing
@testable import Swiftiomatic

@Suite struct RedundantExtensionACLTests {
    @Test func publicExtensionMemberACLStripped() {
        let input = """
        public extension Foo {
            public var bar: Int { 5 }
            private static let baz = "baz"
            public func quux() {}
        }
        """
        let output = """
        public extension Foo {
            var bar: Int { 5 }
            private static let baz = "baz"
            func quux() {}
        }
        """
        testFormatting(
            for: input, output, rule: .redundantExtensionACL,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }

    @Test func privateExtensionMemberACLNotStrippedUnlessFileprivate() {
        let input = """
        private extension Foo {
            fileprivate var bar: Int { 5 }
            private static let baz = "baz"
            fileprivate func quux() {}
        }
        """
        let output = """
        private extension Foo {
            var bar: Int { 5 }
            private static let baz = "baz"
            func quux() {}
        }
        """
        testFormatting(
            for: input, output, rule: .redundantExtensionACL,
            exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
        )
    }
}
