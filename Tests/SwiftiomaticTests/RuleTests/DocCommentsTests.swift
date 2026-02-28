import Testing
@testable import Swiftiomatic

@Suite struct DocCommentsTests {
    @Test func convertCommentsToDocComments() {
        let input = """
        // Multi-line comment before class with
        // attribute between comment and declaration
        @objc
        class Foo {
            // Single line comment before property
            let foo = Foo()

            // Single line comment before property with property wrapper
            @State
            private let bar = Bar()

            // Single line comment
            func foo() {}

            /* Single line block comment before method */
            func baaz() {}

            /*
               Multi-line block comment before method with attribute.

               This comment has a blank line in it.
             */
            @nonobjc
            func baaz() {}
        }

        // Enum with a case
        enum Quux {
            // Documentation on an enum case
            case quux
        }

        extension Collection where Element: Foo {
            // Property in extension with where clause
            var foo: Foo {
                first!
            }
        }
        """

        let output = """
        /// Multi-line comment before class with
        /// attribute between comment and declaration
        @objc
        class Foo {
            /// Single line comment before property
            let foo = Foo()

            /// Single line comment before property with property wrapper
            @State
            private let bar = Bar()

            /// Single line comment
            func foo() {}

            /** Single line block comment before method */
            func baaz() {}

            /**
               Multi-line block comment before method with attribute.

               This comment has a blank line in it.
             */
            @nonobjc
            func baaz() {}
        }

        /// Enum with a case
        enum Quux {
            /// Documentation on an enum case
            case quux
        }

        extension Collection where Element: Foo {
            /// Property in extension with where clause
            var foo: Foo {
                first!
            }
        }
        """

        testFormatting(
            for: input, output, rule: .docComments,
            exclude: [.spaceInsideComments, .propertyTypes],
        )
    }

    @Test func convertDocCommentsToComments() {
        let input = """
        /// Comment not associated with class

        class Foo {
            /** Comment not associated with function */

            func bar() {
                /// Comment inside function declaration.
                /// This one is multi-line.

                /// This comment is inside a function and precedes a declaration,
                /// but we don't want to use doc comments inside property or function
                /// scopes since users typically don't think of these as doc comments,
                /// and this also breaks a common pattern where comments introduce
                /// an entire following block of code (not just the property)
                let bar: Bar? = Bar()
                print(bar)

                #if DEBUG
                    /// This comment is in a conditional compilation block
                    let baaz = Baaz()
                #endif
            }

            var baaz: Baaz {
                /// Comment inside property getter
                let baazImpl = Baaz()
                return baazImpl
            }

            var quux: Quux {
                didSet {
                    /// Comment inside didSet
                    let newQuux = Quux()
                    print(newQuux)
                }
            }
        }
        """

        let output = """
        // Comment not associated with class

        class Foo {
            /* Comment not associated with function */

            func bar() {
                // Comment inside function declaration.
                // This one is multi-line.

                // This comment is inside a function and precedes a declaration,
                // but we don't want to use doc comments inside property or function
                // scopes since users typically don't think of these as doc comments,
                // and this also breaks a common pattern where comments introduce
                // an entire following block of code (not just the property)
                let bar: Bar? = Bar()
                print(bar)

                #if DEBUG
                    // This comment is in a conditional compilation block
                    let baaz = Baaz()
                #endif
            }

            var baaz: Baaz {
                // Comment inside property getter
                let baazImpl = Baaz()
                return baazImpl
            }

            var quux: Quux {
                didSet {
                    // Comment inside didSet
                    let newQuux = Quux()
                    print(newQuux)
                }
            }
        }
        """

        testFormatting(
            for: input, output, rule: .docComments,
            exclude: [.spaceInsideComments, .redundantProperty, .propertyTypes],
        )
    }

    @Test func preservesDocComments() {
        let input = """
        /// Comment not associated with class

        class Foo {
            /** Comment not associated with function */

            // Documentation for function
            func bar() {
                /// Comment inside function declaration.
                /// This one is multi-line.

                /// This comment is inside a function and precedes a declaration.
                /// Since the option to preserve doc comments is enabled,
                /// it should be left as-is.
                let bar: Bar? = Bar()
                print(bar)
            }

            // Documentation for property
            var baaz: Baaz {
                /// Comment inside property getter
                let baazImpl = Baaz()
                return baazImpl
            }

            // Documentation for function
            var quux: Quux {
                didSet {
                    /// Comment inside didSet
                    let newQuux = Quux()
                    print(newQuux)
                }
            }
        }
        """

        let output = """
        /// Comment not associated with class

        class Foo {
            /** Comment not associated with function */

            /// Documentation for function
            func bar() {
                /// Comment inside function declaration.
                /// This one is multi-line.

                /// This comment is inside a function and precedes a declaration.
                /// Since the option to preserve doc comments is enabled,
                /// it should be left as-is.
                let bar: Bar? = Bar()
                print(bar)
            }

            /// Documentation for property
            var baaz: Baaz {
                /// Comment inside property getter
                let baazImpl = Baaz()
                return baazImpl
            }

            /// Documentation for function
            var quux: Quux {
                didSet {
                    /// Comment inside didSet
                    let newQuux = Quux()
                    print(newQuux)
                }
            }
        }
        """

        let options = FormatOptions(preserveDocComments: true)
        testFormatting(
            for: input, output, rule: .docComments, options: options,
            exclude: [.spaceInsideComments, .redundantProperty, .propertyTypes],
        )
    }

    @Test func doesNotConvertCommentBeforeConsecutivePropertiesToDocComment() {
        let input = """
        // Names of the planets
        struct PlanetNames {
            // Inner planets
            let mercury = "Mercury"
            let venus = "Venus"
            let earth = "Earth"
            let mars = "Mars"

            // Inner planets
            let jupiter = "Jupiter"
            let saturn = "Saturn"
            let uranus = "Uranus"
            let neptune = "Neptune"

            /// Dwarf planets
            let pluto = "Pluto"
            let ceres = "Ceres"
        }
        """

        let output = """
        /// Names of the planets
        struct PlanetNames {
            // Inner planets
            let mercury = "Mercury"
            let venus = "Venus"
            let earth = "Earth"
            let mars = "Mars"

            // Inner planets
            let jupiter = "Jupiter"
            let saturn = "Saturn"
            let uranus = "Uranus"
            let neptune = "Neptune"

            /// Dwarf planets
            let pluto = "Pluto"
            let ceres = "Ceres"
        }
        """

        testFormatting(for: input, output, rule: .docComments)
    }

    @Test func convertsCommentsToDocCommentsInConsecutiveDeclarations() {
        let input = """
        // Names of the planets
        enum PlanetNames {
            // Mercuy
            case mercury
            // Venus
            case venus
            // Earth
            case earth
            // Mars
            case mars

            // Jupiter
            case jupiter

            // Saturn
            case saturn

            // Uranus
            case uranus

            // Neptune
            case neptune
        }
        """

        let output = """
        /// Names of the planets
        enum PlanetNames {
            /// Mercuy
            case mercury
            /// Venus
            case venus
            /// Earth
            case earth
            /// Mars
            case mars

            /// Jupiter
            case jupiter

            /// Saturn
            case saturn

            /// Uranus
            case uranus

            /// Neptune
            case neptune
        }
        """

        testFormatting(for: input, output, rule: .docComments)
    }

    @Test func doesNotConvertCommentBeforeConsecutiveEnumCasesToDocComment() {
        let input = """
        // Names of the planets
        enum PlanetNames {
            // Inner planets
            case mercury
            case venus
            case earth
            case mars

            // Inner planets
            case jupiter
            case saturn
            case uranus
            case neptune

            // Dwarf planets
            case pluto
            case ceres
        }
        """

        let output = """
        /// Names of the planets
        enum PlanetNames {
            // Inner planets
            case mercury
            case venus
            case earth
            case mars

            // Inner planets
            case jupiter
            case saturn
            case uranus
            case neptune

            // Dwarf planets
            case pluto
            case ceres
        }
        """

        testFormatting(for: input, output, rule: .docComments)
    }

    @Test func doesNotConvertAnnotationCommentsToDocComments() {
        let input = """
        // swiftformat:disable some_swift_format_rule
        let testSwiftLint: Foo
        let testSwiftLint: Foo

        // sourcery:directive
        let testSourcery: Foo
        """

        testFormatting(for: input, rule: .docComments)
    }

    @Test func doesNotConvertTODOCommentsToDocComments() {
        let input = """
        // TODO: Clean up this mess
        func doSomething() {}
        """

        testFormatting(for: input, rule: .docComments)
    }

    @Test func doesNotConvertCommentAfterTODOToDocComments() {
        let input = """
        // TODO: Clean up this mess
        // because it's bothering me
        func doSomething() {}
        """
        testFormatting(for: input, rule: .docComments)
    }

    @Test func doesNotConvertCommentBeforeTODOToDocComments() {
        let input = """
        // Something, something
        // TODO: Clean up this mess
        func doSomething() {}
        """
        testFormatting(for: input, rule: .docComments)
    }

    @Test func convertNoteCommentsToDocComments() {
        let input = """
        // Does something
        // Note: not really
        func doSomething() {}
        """
        let output = """
        /// Does something
        /// Note: not really
        func doSomething() {}
        """
        testFormatting(for: input, output, rule: .docComments)
    }

    @Test func convertURLCommentsToDocComments() {
        let input = """
        // Does something
        // http://example.com
        func doSomething() {}
        """
        let output = """
        /// Does something
        /// http://example.com
        func doSomething() {}
        """
        testFormatting(for: input, output, rule: .docComments)
    }

    @Test func multilineDocCommentReplaced() {
        let input = """
        // A class
        // With some other details
        class Foo {}
        """
        let output = """
        /// A class
        /// With some other details
        class Foo {}
        """
        testFormatting(for: input, output, rule: .docComments)
    }

    @Test func commentWithBlankLineNotReplaced() {
        let input = """
        // A class
        // With some other details

        class Foo {}
        """
        testFormatting(for: input, rule: .docComments)
    }

    @Test func docCommentsAssociatedTypeNotReplaced() {
        let input = """
        /// An interesting comment about Foo.
        associatedtype Foo
        """
        testFormatting(for: input, rule: .docComments)
    }

    @Test func nonDocCommentsAssociatedTypeReplaced() {
        let input = """
        // An interesting comment about Foo.
        associatedtype Foo
        """
        let output = """
        /// An interesting comment about Foo.
        associatedtype Foo
        """
        testFormatting(for: input, output, rule: .docComments)
    }

    @Test func conditionalDeclarationCommentNotReplaced() {
        let input = """
        if let foo = bar,
           // baz
           let baz = bar
        {}
        """
        testFormatting(for: input, rule: .docComments)
    }

    @Test func commentInsideSwitchCaseNotReplaced() {
        let input = """
        switch foo {
        case .bar:
            // bar
            let bar = baz()

        default:
            // baz
            let baz = quux()
        }
        """
        testFormatting(for: input, rule: .docComments)
    }

    @Test func docCommentInsideIfdef() {
        let input = """
        #if DEBUG
            // return 3
            func returnNumber() { 3 }
        #endif
        """
        let output = """
        #if DEBUG
            /// return 3
            func returnNumber() { 3 }
        #endif
        """
        testFormatting(for: input, output, rule: .docComments, exclude: [.wrapFunctionBodies])
    }

    @Test func docCommentInsideIfdefElse() {
        let input = """
        #if DEBUG
        #elseif PROD
            /// return 2
            func returnNumber() { 2 }
        #else
            /// return 3
            func returnNumber() { 3 }
        #endif
        """
        testFormatting(for: input, rule: .docComments, exclude: [.wrapFunctionBodies])
    }

    @Test func docCommentForMacro() {
        let input = """
        /// Adds a static `logger` member to the type.
        @attached(member, names: named(logger)) public macro StaticLogger(
            subsystem: String? = nil,
            category: String? = nil
        ) = #externalMacro(module: "StaticLoggerMacros", type: "StaticLogger")
        """
        testFormatting(for: input, rule: .docComments)
    }

    @Test func commentsTrailingDeclarationPreservedAsRegularComment() {
        let input = """
        // Comment
        let foo: Foo // Foo
        let bar: Bar // Bar
        """

        testFormatting(for: input, rule: .docComments)
    }

    @Test func docCommentsTrailingDeclarationConvertedToRegularComment() {
        let input = """
        // Comment
        let foo: Foo /// Foo
        let foo: bar /// Bar

        """

        let output = """
        // Comment
        let foo: Foo // Foo
        let foo: bar // Bar

        """

        testFormatting(for: input, output, rule: .docComments)
    }

    @Test func docCommentsAfterSwitchCase() {
        let input = """
        func foo() {
            switch bar {
            case .foo:
                break
            default:
                break
            }
        }

        /// Baz
        func baz() {}
        """

        testFormatting(for: input, rule: .docComments)
    }

    @Test func docCommentsAfterConditionalSwitchCase() {
        let input = """
        func foo() {
            switch bar {
            #if DEBUG
                case .foo:
                    break
            #endif
            default:
                break
            }
        }

        /// Baz
        func baz() {}
        """

        testFormatting(for: input, rule: .docComments)
    }

    @Test func preserveDocCommentContinuousWithMarkComment() {
        let input = """
        // MARK: - PlaceholderFlowOrigin
        /// Placeholder text describing a sample flow origin.
        public enum PlaceholderFlowOrigin {
            case standard(ScreenAuthenticationType)
            case premium(sampleType: ScreenAuthenticationType?)
        }
        """

        testFormatting(for: input, rule: .docComments, exclude: [.blankLinesAroundMark])
    }

    @Test func preserveDocCommentAfterSwiftFormatDirective() {
        let input = """
        // swiftformat:enable docComments
        /// Placeholder text describing a sample flow origin.
        public enum PlaceholderFlowOrigin {
            case standard(ScreenAuthenticationType)
            case premium(sampleType: ScreenAuthenticationType?)
        }
        """

        testFormatting(for: input, rule: .docComments)
    }

    @Test func preserveDocCommentBeforeSwiftFormatDirective() {
        let input = """
        /// Placeholder text describing a sample flow origin.
        // swiftformat:enable:next docComments
        public enum PlaceholderFlowOrigin {
            case standard(ScreenAuthenticationType)
            case premium(sampleType: ScreenAuthenticationType?)
        }
        """

        testFormatting(for: input, rule: .docComments)
    }

    @Test func docCommentOnNestedFunction() {
        let input = """
        // Parent function at file scope
        func parentFunction() {
            // Nested function inside parent function
            func nestedFunction() {
                print("foo bar")
            }
        }
        """

        let output = """
        /// Parent function at file scope
        func parentFunction() {
            /// Nested function inside parent function
            func nestedFunction() {
                print("foo bar")
            }
        }
        """

        testFormatting(for: input, output, rule: .docComments)
    }
}
