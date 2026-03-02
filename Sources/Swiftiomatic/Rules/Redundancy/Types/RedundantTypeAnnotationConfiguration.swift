struct RedundantTypeAnnotationConfiguration: RuleConfiguration {
    let id = "redundant_type_annotation"
    let name = "Redundant Type Annotation"
    let summary = "Variables should not have redundant type annotation"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("var url = URL()"),
              Example("var url: CustomStringConvertible = URL()"),
              Example("var one: Int = 1, two: Int = 2, three: Int"),
              Example("guard let url = URL() else { return }"),
              Example("if let url = URL() { return }"),
              Example("let alphanumerics = CharacterSet.alphanumerics"),
              Example("var set: Set<Int> = Set([])"),
              Example("var set: Set<Int> = Set.init([])"),
              Example("var set = Set<Int>([])"),
              Example("var set = Set<Int>.init([])"),
              Example("guard var set: Set<Int> = Set([]) else { return }"),
              Example("if var set: Set<Int> = Set.init([]) { return }"),
              Example("guard var set = Set<Int>([]) else { return }"),
              Example("if var set = Set<Int>.init([]) { return }"),
              Example("var one: A<T> = B()"),
              Example("var one: A = B<T>()"),
              Example("var one: A<T> = B<T>()"),
              Example("let a = A.b.c.d"),
              Example("let a: B = A.b.c.d"),
              Example(
                """
                enum Direction {
                    case up
                    case down
                }

                var direction: Direction = .up
                """,
              ),
              Example(
                """
                enum Direction {
                    case up
                    case down
                }

                var direction = Direction.up
                """,
              ),
              Example(
                "@IgnoreMe var a: Int = Int(5)",
                configuration: ["ignore_attributes": ["IgnoreMe"]],
              ),
              Example(
                """
                var a: Int {
                    @IgnoreMe let i: Int = Int(1)
                    return i
                }
                """, configuration: ["ignore_attributes": ["IgnoreMe"]],
              ),
              Example("var bol: Bool = true"),
              Example("var dbl: Double = 0.0"),
              Example("var int: Int = 0"),
              Example("var str: String = \"str\""),
              Example(
                """
                struct Foo {
                    var url: URL = URL()
                    let myVar: Int? = 0, s: String = ""
                }
                """, configuration: ["ignore_properties": true],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("var url↓:URL=URL()"),
              Example("var url↓:URL = URL(string: \"\")"),
              Example("var url↓: URL = URL()"),
              Example("let url↓: URL = URL()"),
              Example("lazy var url↓: URL = URL()"),
              Example("let url↓: URL = URL()!"),
              Example("var one: Int = 1, two↓: Int = Int(5), three: Int"),
              Example("guard let url↓: URL = URL() else { return }"),
              Example("if let url↓: URL = URL() { return }"),
              Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"),
              Example("var set↓: Set<Int> = Set<Int>([])"),
              Example("var set↓: Set<Int> = Set<Int>.init([])"),
              Example("var set↓: Set = Set<Int>([])"),
              Example("var set↓: Set = Set<Int>.init([])"),
              Example("guard var set↓: Set = Set<Int>([]) else { return }"),
              Example("if var set↓: Set = Set<Int>.init([]) { return }"),
              Example("guard var set↓: Set<Int> = Set<Int>([]) else { return }"),
              Example("if var set↓: Set<Int> = Set<Int>.init([]) { return }"),
              Example("var set↓: Set = Set<Int>([]), otherSet: Set<Int>"),
              Example("var num↓: Int = Int.random(0..<10)"),
              Example("let a↓: A = A.b.c.d"),
              Example("let a↓: A = A.f().b"),
              Example(
                """
                class ViewController: UIViewController {
                  func someMethod() {
                    let myVar↓: Int = Int(5)
                  }
                }
                """,
              ),
              Example(
                """
                class ViewController: UIViewController {
                  func someMethod() {
                    let myVar↓: Int = Int(5)
                  }
                }
                """, configuration: ["ignore_properties": true],
              ),
              Example("let a↓: [Int] = [Int]()"),
              Example("let a↓: A.B = A.B()"),
              Example(
                """
                enum Direction {
                    case up
                    case down
                }

                var direction↓: Direction = Direction.up
                """,
              ),
              Example(
                "@DontIgnoreMe var a↓: Int = Int(5)",
                configuration: ["ignore_attributes": ["IgnoreMe"]],
              ),
              Example(
                """
                @IgnoreMe
                var a: Int {
                    let i↓: Int = Int(1)
                    return i
                }
                """, configuration: ["ignore_attributes": ["IgnoreMe"]],
              ),
              Example(
                "var bol↓: Bool = true",
                configuration: ["consider_default_literal_types_redundant": true],
              ),
              Example(
                "var dbl↓: Double = 0.0",
                configuration: ["consider_default_literal_types_redundant": true],
              ),
              Example(
                "var int↓: Int = 0",
                configuration: ["consider_default_literal_types_redundant": true],
              ),
              Example(
                "var str↓: String = \"str\"",
                configuration: ["consider_default_literal_types_redundant": true],
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("var url↓: URL = URL()"): Example("var url = URL()"),
              Example("let url↓: URL = URL()"): Example("let url = URL()"),
              Example("var one: Int = 1, two↓: Int = Int(5), three: Int"):
                Example("var one: Int = 1, two = Int(5), three: Int"),
              Example("guard let url↓: URL = URL() else { return }"):
                Example("guard let url = URL() else { return }"),
              Example("if let url↓: URL = URL() { return }"):
                Example("if let url = URL() { return }"),
              Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"):
                Example("let alphanumerics = CharacterSet.alphanumerics"),
              Example("var set↓: Set<Int> = Set<Int>([])"):
                Example("var set = Set<Int>([])"),
              Example("var set↓: Set<Int> = Set<Int>.init([])"):
                Example("var set = Set<Int>.init([])"),
              Example("var set↓: Set = Set<Int>([])"):
                Example("var set = Set<Int>([])"),
              Example("var set↓: Set = Set<Int>.init([])"):
                Example("var set = Set<Int>.init([])"),
              Example("guard var set↓: Set<Int> = Set<Int>([]) else { return }"):
                Example("guard var set = Set<Int>([]) else { return }"),
              Example("if var set↓: Set<Int> = Set<Int>.init([]) { return }"):
                Example("if var set = Set<Int>.init([]) { return }"),
              Example("var set↓: Set = Set<Int>([]), otherSet: Set<Int>"):
                Example("var set = Set<Int>([]), otherSet: Set<Int>"),
              Example("let a↓: A = A.b.c.d"):
                Example("let a = A.b.c.d"),
              Example(
                """
                class ViewController: UIViewController {
                  func someMethod() {
                    let myVar↓: Int = Int(5)
                  }
                }
                """,
              ):
                Example(
                  """
                  class ViewController: UIViewController {
                    func someMethod() {
                      let myVar = Int(5)
                    }
                  }
                  """,
                ),
              Example("var num: Int = Int.random(0..<10)"): Example("var num = Int.random(0..<10)"),
              Example(
                """
                @IgnoreMe
                var a: Int {
                    let i↓: Int = Int(1)
                    return i
                }
                """, configuration: ["ignore_attributes": ["IgnoreMe"]],
              ):
                Example(
                  """
                  @IgnoreMe
                  var a: Int {
                      let i = Int(1)
                      return i
                  }
                  """,
                ),
              Example(
                "var bol: Bool = true",
                configuration: ["consider_default_literal_types_redundant": true],
              ):
                Example("var bol = true"),
              Example(
                "var dbl: Double = 0.0",
                configuration: ["consider_default_literal_types_redundant": true],
              ):
                Example("var dbl = 0.0"),
              Example(
                "var int: Int = 0",
                configuration: ["consider_default_literal_types_redundant": true],
              ):
                Example("var int = 0"),
              Example(
                "var str: String = \"str\"",
                configuration: ["consider_default_literal_types_redundant": true],
              ):
                Example("var str = \"str\""),
            ]
    }
}
