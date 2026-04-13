import SwiftiomaticSyntax

extension DontRepeatTypeInStaticPropertiesRule {
  static var nonTriggeringExamples: [Example] {
    [
      // Name doesn't repeat type
      Example(
        """
        struct Color {
            static let green: Color = .init()
        }
        """
      ),
      // Instance property — not static
      Example(
        """
        class UIColor {
            var yellowColor: UIColor = .init()
        }
        """
      ),
      // Return type doesn't match enclosing type
      Example(
        """
        extension UIImage {
            static let fooImage: Int = 0
        }
        """
      ),
      // Static property where name equals the bare type (no extra prefix)
      Example(
        """
        struct Foo {
            static let foo: Foo = .init()
        }
        """,
        isExcludedFromDocumentation: true
      ),
      // Not inside a type
      Example(
        """
        static let sharedColor: Color = .init()
        """,
        isExcludedFromDocumentation: true
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // Type name repeated as suffix — explicit type annotation
      Example(
        """
        class UIColor {
            static let ↓redColor: UIColor = .init()
        }
        """
      ),
      // Type name repeated as suffix — class var
      Example(
        """
        class UIColor {
            class var ↓blueColor: UIColor { .init() }
        }
        """
      ),
      // Enum with type suffix
      Example(
        """
        enum Sandwich {
            static let ↓bolognaSandwich: Sandwich = .init()
        }
        """
      ),
      // Struct with type suffix
      Example(
        """
        struct TVGame {
            static var ↓basketballGame: TVGame = .init()
        }
        """
      ),
      // Extension with namespace prefix stripped
      Example(
        """
        extension URLSession {
            class var ↓sharedSession: URLSession { .init() }
        }
        """
      ),
      // Actor
      Example(
        """
        actor Cookie {
            static let ↓chocolateChipCookie: Cookie = .init()
        }
        """
      ),
      // Self type annotation
      Example(
        """
        struct Thing {
            static let ↓defaultThing: Self = .init()
        }
        """
      ),
      // Initializer expression (no type annotation)
      Example(
        """
        struct Foo {
            static let ↓defaultFoo = Foo()
        }
        """
      ),
      // Explicit .init() call
      Example(
        """
        struct Foo {
            static let ↓defaultFoo = Foo.init()
        }
        """
      ),
      // Self() initializer
      Example(
        """
        struct Foo {
            static let ↓defaultFoo = Self()
        }
        """
      ),
    ]
  }
}
