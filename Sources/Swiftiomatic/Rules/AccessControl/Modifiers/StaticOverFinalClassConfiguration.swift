struct StaticOverFinalClassConfiguration: RuleConfiguration {
    let id = "static_over_final_class"
    let name = "Static Over Final Class"
    let summary = ""
    var nonTriggeringExamples: [Example] {
        [
                    Example(
                        """
                        class C {
                            static func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            static var i: Int { 0 }
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            static subscript(_: Int) -> Int { 0 }
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            class func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        final class C {}
                        """,
                    ),
                    Example(
                        """
                        final class C {
                            class D {
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
                        class C {
                            ↓final class func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            ↓final class var i: Int { 0 }
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            ↓final class subscript(_: Int) -> Int { 0 }
                        }
                        """,
                    ),
                    Example(
                        """
                        final class C {
                            ↓class func f() {}
                        }
                        """,
                    ),
                    Example(
                        """
                        class C {
                            final class D {
                                ↓class func f() {}
                            }
                        }
                        """,
                    ),
                ]
    }
}
