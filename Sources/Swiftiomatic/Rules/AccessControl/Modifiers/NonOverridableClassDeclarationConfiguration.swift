struct NonOverridableClassDeclarationConfiguration: RuleConfiguration {
    let id = "non_overridable_class_declaration"
    let name = "Class Declaration in Final Class"
    let summary = ""
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
                    Example(
                        """
                        final class C {
                            final class var b: Bool { true }
                            final class func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            final class var b: Bool { true }
                            final class func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            class var b: Bool { true }
                            class func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            static var b: Bool { true }
                            static func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        final class C {
                            static var b: Bool { true }
                            static func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        final class C {
                            class D {
                                class var b: Bool { true }
                                class func f() {}
                            }
                        }
                        """,
                    ),
                ]
    }
    var triggeringExamples: [Example] {
        [
                    Example(
                        """
                        final class C {
                            ↓class var b: Bool { true }
                            ↓class func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            final class D {
                                ↓class var b: Bool { true }
                                ↓class func f() {}
                            }
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            private ↓class var b: Bool { true }
                            private ↓class func f() {}
                        }
                        """,
                    ),
                ]
    }
    var corrections: [Example: Example] {
        [
                    Example(
                        """
                        final class C {
                            class func f() {}
                        }
                        """,
                    ): Example(
                        """
                        final class C {
                            final class func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        final class C {
                            class var b: Bool { true }
                        }
                        """, configuration: ["final_class_modifier": "static"],
                    ): Example(
                        """
                        final class C {
                            static var b: Bool { true }
                        }
                        """,
                    ),
                ]
    }
}
