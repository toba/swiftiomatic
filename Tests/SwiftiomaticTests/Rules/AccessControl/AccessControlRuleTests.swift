import Testing

@testable import Swiftiomatic

// MARK: - ModifiersOnSameLineRule

@Suite(.rulesRegistered)
struct ModifiersOnSameLineRuleTests {
    @Test func noViolationForSameLineModifiers() async {
        await assertNoViolation(ModifiersOnSameLineRule.self, "public var foo: Int")
    }

    @Test func detectsModifierOnSeparateLine() async {
        await assertViolates(ModifiersOnSameLineRule.self, """
            public
            private(set)
            var foo: Int
            """)
    }
}

// MARK: - NoExplicitOwnershipRule

@Suite(.rulesRegistered)
struct NoExplicitOwnershipRuleTests {
    @Test func noViolationWithoutOwnership() async {
        await assertNoViolation(NoExplicitOwnershipRule.self, "func foo(_ bar: Bar) {}")
    }

    @Test func detectsConsumingKeyword() async {
        await assertViolates(NoExplicitOwnershipRule.self, "func foo(_ bar: consuming Bar) {}")
    }
}

// MARK: - ExtensionAccessControlRule

@Suite(.rulesRegistered)
struct ExtensionAccessControlRuleTests {
    @Test func noViolationForExtensionACL() async {
        await assertNoViolation(ExtensionAccessControlRule.self, """
            public extension Foo {
                func bar() {}
                func baz() {}
            }
            """)
    }

    @Test func noViolationForMixedACL() async {
        await assertNoViolation(ExtensionAccessControlRule.self, """
            extension Foo {
                public func bar() {}
                internal func baz() {}
            }
            """)
    }

    @Test func detectsRepeatedACLInExtension() async {
        await assertViolates(ExtensionAccessControlRule.self, """
            extension Foo {
                public func bar() {}
                public func baz() {}
            }
            """)
    }
}
