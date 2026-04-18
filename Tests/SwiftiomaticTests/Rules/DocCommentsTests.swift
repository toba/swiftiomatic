@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DocCommentsTests: RuleTesting {

  // MARK: - Convert // to /// for API Declarations

  @Test func convertSingleLineCommentToDocComment() {
    assertFormatting(DocComments.self,
      input: """
        // A function
        1️⃣func foo() {}
        """,
      expected: """
        /// A function
        func foo() {}
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  @Test func convertMultilineCommentToDocComment() {
    assertFormatting(DocComments.self,
      input: """
        // A class
        // With some other details
        1️⃣class Foo {}
        """,
      expected: """
        /// A class
        /// With some other details
        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  @Test func convertCommentBeforePropertyInType() {
    assertFormatting(DocComments.self,
      input: """
        class Foo {
            // A property
            1️⃣let bar = 1
        }
        """,
      expected: """
        class Foo {
            /// A property
            let bar = 1
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  @Test func convertCommentBeforeMethodInType() {
    assertFormatting(DocComments.self,
      input: """
        struct Foo {
            // A method
            1️⃣func bar() {}
        }
        """,
      expected: """
        struct Foo {
            /// A method
            func bar() {}
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  @Test func convertCommentBeforeEnumCase() {
    assertFormatting(DocComments.self,
      input: """
        enum Foo {
            // A case
            1️⃣case bar
        }
        """,
      expected: """
        enum Foo {
            /// A case
            case bar
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  @Test func convertCommentBeforeAssociatedType() {
    assertFormatting(DocComments.self,
      input: """
        protocol Foo {
            // An associated type
            1️⃣associatedtype Bar
        }
        """,
      expected: """
        protocol Foo {
            /// An associated type
            associatedtype Bar
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  @Test func convertCommentBeforeDeclarationWithAttribute() {
    assertFormatting(DocComments.self,
      input: """
        // A class with attribute
        1️⃣@objc
        class Foo {}
        """,
      expected: """
        /// A class with attribute
        @objc
        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  @Test func convertBlockCommentToDocBlockComment() {
    assertFormatting(DocComments.self,
      input: """
        struct Foo {
            /* A method */
            1️⃣func bar() {}
        }
        """,
      expected: """
        struct Foo {
            /** A method */
            func bar() {}
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  // MARK: - Convert /// to // Inside Function Bodies

  @Test func convertDocCommentToRegularInsideFunction() {
    assertFormatting(DocComments.self,
      input: """
        func foo() {
            /// A local variable
            1️⃣let bar = 1
        }
        """,
      expected: """
        func foo() {
            // A local variable
            let bar = 1
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use regular comment (//) inside implementation")])
  }

  @Test func convertDocCommentInsidePropertyGetter() {
    assertFormatting(DocComments.self,
      input: """
        class Foo {
            var bar: Int {
                /// A local
                1️⃣let x = 1
                return x
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int {
                // A local
                let x = 1
                return x
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use regular comment (//) inside implementation")])
  }

  @Test func convertDocCommentInsideDidSet() {
    assertFormatting(DocComments.self,
      input: """
        class Foo {
            var bar: Int {
                didSet {
                    /// A local
                    1️⃣let x = bar
                    print(x)
                }
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int {
                didSet {
                    // A local
                    let x = bar
                    print(x)
                }
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use regular comment (//) inside implementation")])
  }

  @Test func nestedFunctionGetsDocComment() {
    assertFormatting(DocComments.self,
      input: """
        // Parent function
        1️⃣func parentFunction() {
            // Nested function
            2️⃣func nestedFunction() {
                print("hello")
            }
        }
        """,
      expected: """
        /// Parent function
        func parentFunction() {
            /// Nested function
            func nestedFunction() {
                print("hello")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use doc comment (///) for API declarations"),
        FindingSpec("2️⃣", message: "use doc comment (///) for API declarations"),
      ])
  }

  // MARK: - Blank Line Gap

  @Test func commentWithBlankLineNotConverted() {
    assertFormatting(DocComments.self,
      input: """
        // A comment

        class Foo {}
        """,
      expected: """
        // A comment

        class Foo {}
        """,
      findings: [])
  }

  @Test func docCommentWithBlankLineConvertedToRegular() {
    assertFormatting(DocComments.self,
      input: """
        /// Comment not associated with class

        1️⃣class Foo {}
        """,
      expected: """
        // Comment not associated with class

        class Foo {}
        """,
      findings: [FindingSpec("1️⃣", message: "use regular comment (//) inside implementation")])
  }

  // MARK: - Directives

  @Test func markDirectiveNotConverted() {
    assertFormatting(DocComments.self,
      input: """
        // MARK: - Section
        func foo() {}
        """,
      expected: """
        // MARK: - Section
        func foo() {}
        """,
      findings: [])
  }

  @Test func todoDirectiveNotConverted() {
    assertFormatting(DocComments.self,
      input: """
        // TODO: Clean up this mess
        func doSomething() {}
        """,
      expected: """
        // TODO: Clean up this mess
        func doSomething() {}
        """,
      findings: [])
  }

  @Test func commentAfterTodoNotConverted() {
    assertFormatting(DocComments.self,
      input: """
        // TODO: Clean up this mess
        // because it's bothering me
        func doSomething() {}
        """,
      expected: """
        // TODO: Clean up this mess
        // because it's bothering me
        func doSomething() {}
        """,
      findings: [])
  }

  @Test func commentBeforeTodoNotConverted() {
    assertFormatting(DocComments.self,
      input: """
        // Something, something
        // TODO: Clean up this mess
        func doSomething() {}
        """,
      expected: """
        // Something, something
        // TODO: Clean up this mess
        func doSomething() {}
        """,
      findings: [])
  }

  @Test func swiftformatDirectiveNotConverted() {
    assertFormatting(DocComments.self,
      input: """
        // swiftformat:disable some_rule
        let foo = 1
        """,
      expected: """
        // swiftformat:disable some_rule
        let foo = 1
        """,
      findings: [])
  }

  @Test func noteCommentConverted() {
    assertFormatting(DocComments.self,
      input: """
        // Does something
        // Note: not really
        1️⃣func doSomething() {}
        """,
      expected: """
        /// Does something
        /// Note: not really
        func doSomething() {}
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  // MARK: - Consecutive Declarations

  @Test func sectionHeaderNotConvertedBeforeConsecutiveProperties() {
    assertFormatting(DocComments.self,
      input: """
        struct PlanetNames {
            // Inner planets
            let mercury = "Mercury"
            let venus = "Venus"
            let earth = "Earth"
        }
        """,
      expected: """
        struct PlanetNames {
            // Inner planets
            let mercury = "Mercury"
            let venus = "Venus"
            let earth = "Earth"
        }
        """,
      findings: [])
  }

  @Test func sectionHeaderNotConvertedBeforeConsecutiveCases() {
    assertFormatting(DocComments.self,
      input: """
        enum Planets {
            // Inner planets
            case mercury
            case venus
            case earth
        }
        """,
      expected: """
        enum Planets {
            // Inner planets
            case mercury
            case venus
            case earth
        }
        """,
      findings: [])
  }

  @Test func perDeclarationCommentsConvertedEvenIfConsecutive() {
    assertFormatting(DocComments.self,
      input: """
        enum Planets {
            // Mercury
            1️⃣case mercury
            // Venus
            2️⃣case venus
            // Earth
            3️⃣case earth
        }
        """,
      expected: """
        enum Planets {
            /// Mercury
            case mercury
            /// Venus
            case venus
            /// Earth
            case earth
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use doc comment (///) for API declarations"),
        FindingSpec("2️⃣", message: "use doc comment (///) for API declarations"),
        FindingSpec("3️⃣", message: "use doc comment (///) for API declarations"),
      ])
  }

  // MARK: - Conditional Compilation

  @Test func docCommentInsideIfdef() {
    assertFormatting(DocComments.self,
      input: """
        #if DEBUG
        // A function
        1️⃣func returnNumber() -> Int { 3 }
        #endif
        """,
      expected: """
        #if DEBUG
        /// A function
        func returnNumber() -> Int { 3 }
        #endif
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }

  @Test func docCommentInsideIfdefInFunctionBody() {
    assertFormatting(DocComments.self,
      input: """
        func foo() {
            #if DEBUG
            /// A local
            1️⃣let bar = 1
            #endif
        }
        """,
      expected: """
        func foo() {
            #if DEBUG
            // A local
            let bar = 1
            #endif
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use regular comment (//) inside implementation")])
  }

  // MARK: - Switch Case Bodies

  @Test func commentInsideSwitchCaseNotConverted() {
    assertFormatting(DocComments.self,
      input: """
        func foo() {
            switch bar {
            case .baz:
                // a comment
                let x = 1
                print(x)
            default:
                // another comment
                let y = 2
                print(y)
            }
        }
        """,
      expected: """
        func foo() {
            switch bar {
            case .baz:
                // a comment
                let x = 1
                print(x)
            default:
                // another comment
                let y = 2
                print(y)
            }
        }
        """,
      findings: [])
  }

  // MARK: - Preserve Existing Doc Comments

  @Test func existingDocCommentsPreservedOnAPIDeclarations() {
    assertFormatting(DocComments.self,
      input: """
        /// Already a doc comment
        class Foo {}
        """,
      expected: """
        /// Already a doc comment
        class Foo {}
        """,
      findings: [])
  }

  @Test func preserveDocCommentAfterMark() {
    assertFormatting(DocComments.self,
      input: """
        // MARK: - Foo
        /// A doc comment
        enum Foo {
            case bar
        }
        """,
      expected: """
        // MARK: - Foo
        /// A doc comment
        enum Foo {
            case bar
        }
        """,
      findings: [])
  }

  // MARK: - Extension Members

  @Test func convertCommentInExtension() {
    assertFormatting(DocComments.self,
      input: """
        extension Foo {
            // A property
            1️⃣var bar: Int { 0 }
        }
        """,
      expected: """
        extension Foo {
            /// A property
            var bar: Int { 0 }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use doc comment (///) for API declarations")])
  }
}
