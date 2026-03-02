struct NoMagicNumbersConfiguration: RuleConfiguration {
    let id = "no_magic_numbers"
    let name = "No Magic Numbers"
    let summary = "Magic numbers should be replaced by named constants"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("var foo = 123"),
              Example("static let bar: Double = 0.123"),
              Example("let a = b + 1.0"),
              Example("array[0] + array[1] "),
              Example("let foo = 1_000.000_01"),
              Example("// array[1337]"),
              Example("baz(\"9999\")"),
              Example(
                """
                func foo() {
                    let x: Int = 2
                    let y = 3
                    let vector = [x, y, -1]
                }
                """,
              ),
              Example(
                """
                class A {
                    var foo: Double = 132
                    static let bar: Double = 0.98
                }
                """,
              ),
              Example(
                """
                @available(iOS 13, *)
                func version() {
                    if #available(iOS 13, OSX 10.10, *) {
                        return
                    }
                }
                """,
              ),
              Example(
                """
                enum Example: Int {
                    case positive = 2
                    case negative = -2
                }
                """,
              ),
              Example(
                """
                class FooTests: XCTestCase {
                    let array: [Int] = []
                    let bar = array[42]
                }
                """,
              ),
              Example(
                """
                class FooTests: XCTestCase {
                    class Bar {
                        let array: [Int] = []
                        let bar = array[42]
                    }
                }
                """,
              ),
              Example(
                """
                class MyTest: XCTestCase {}
                extension MyTest {
                    let a = Int(3)
                }
                """,
              ),
              Example(
                """
                extension MyTest {
                    let a = Int(3)
                }
                class MyTest: XCTestCase {}
                """,
              ),
              Example("let foo = 1 << 2"),
              Example("let foo = 1 >> 2"),
              Example("let foo = 2 >> 2"),
              Example("let foo = 2 << 2"),
              Example("let a = b / 100.0"),
              Example("let range = 2 ..< 12"),
              Example("let range = ...12"),
              Example("let range = 12..."),
              Example("let (lowerBound, upperBound) = (400, 599)"),
              Example("let a = (5, 10)"),
              Example("let notFound = (statusCode: 404, description: \"Not Found\", isError: true)"),
              Example("#Preview { ContentView(value: 5) }"),
              Example("@Test func f() { let _ = 2 + 2 }"),
              Example(
                """
                @Suite struct Test {
                    @Test func f() {
                        func g() { let _ = 2 + 2 }
                        let _ = 2 + 2
                    }
                }
                """,
              ),
              Example(
                """
                @Suite actor Test {
                    private var a: Int { 2 }
                    @Test func f() { let _ = 2 + a }
                }
                """,
              ),
              Example(
                """
                class Test { // @Suite implicitly
                    private var a: Int { 2 }
                    @Test func f() { let _ = 2 + a }
                }
                """,
              ),
              Example(
                """
                #if compiler(<6.0) && compiler(>4.0)
                let a = 1
                #elseif compiler(<3.0)
                let a = 2
                #endif
                """,
              ),
              Example(
                """
                let myColor: UIColor = UIColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 0.52)
                """,
              ),
              Example(
                """
                let colorLiteral = #colorLiteral(red: 0.7019607843, green: 0.7019607843, blue: 0.7019607843, alpha: 1)
                """,
              ),
              Example(
                """
                let yourColor: UIColor = UIColor(hue: 0.9, saturation: 0.6, brightness: 0.333334, alpha: 1.0)
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                let systemColor = UIColor(displayP3Red: 0.3, green: 0.8, blue: 0.5, alpha: 0.75)
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                func createColor() -> UIColor {
                    return UIColor(white: 0.5, alpha: 0.8)
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                let memberColor = UIColor.init(red: 0.5, green: 0.3, blue: 0.9, alpha: 1.0)
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                func createMemberColor() -> UIColor {
                    return UIColor.init(hue: 0.2, saturation: 0.8, brightness: 0.7, alpha: 0.5)
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                "let a = b + 2", configuration: ["allowed_numbers": [2]],
                isExcludedFromDocumentation: true,
              ),
              Example(
                "let a = b + 2", configuration: ["allowed_numbers": [2.0]],
                isExcludedFromDocumentation: true,
              ),
              Example(
                "let a = b + 1", configuration: ["allowed_numbers": [2.0]],
                isExcludedFromDocumentation: true,
              ),
              Example(
                "let a = b + 2.5", configuration: ["allowed_numbers": [2.5]],
                isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("foo(↓321)"),
              Example("bar(↓1_000.005_01)"),
              Example("array[↓42]"),
              Example("let box = array[↓12 + ↓14]"),
              Example("let a = b + ↓2.0"),
              Example("let range = 2 ... ↓12 + 1"),
              Example("let range = ↓2*↓6..."),
              Example("let slice = array[↓2...↓4]"),
              Example("for i in ↓3 ..< ↓8 {}"),
              Example("let n: Int = Int(r * ↓255) << ↓16 | Int(g * ↓255) << ↓8"),
              Example("Color.primary.opacity(isAnimate ? ↓0.1 : ↓1.5)"),
              Example(
                """
                        class MyTest: XCTestCase {}
                        extension NSObject {
                            let a = Int(↓3)
                        }
                """,
              ),
              Example(
                """
                if (fileSize > ↓1000000) {
                    return
                }
                """,
              ),
              Example("let imageHeight = (width - ↓24)"),
              Example("return (↓5, ↓10, ↓15)"),
              Example(
                """
                #ExampleMacro {
                    ContentView(value: ↓5)
                }
                """,
              ),
              Example(
                """
                #if compiler(<6.0) && compiler(>4.0)
                f(↓6.0)
                #elseif compiler(<3.0)
                f(↓3.0)
                #else
                f(↓4.0)
                #endif
                """,
              ),
              Example(
                "let a = b + ↓3", configuration: ["allowed_numbers": [2.0]],
                isExcludedFromDocumentation: true,
              ),
            ]
    }
}
