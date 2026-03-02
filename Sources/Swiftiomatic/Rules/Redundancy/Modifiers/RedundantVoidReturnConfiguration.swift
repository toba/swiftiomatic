struct RedundantVoidReturnConfiguration: RuleConfiguration {
    let id = "redundant_void_return"
    let name = "Redundant Void Return"
    let summary = "Returning Void in a function declaration is redundant"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func foo() {}"),
              Example("func foo() -> Int {}"),
              Example("func foo() -> Int -> Void {}"),
              Example("func foo() -> VoidResponse"),
              Example("let foo: (Int) -> Void"),
              Example("func foo() -> Int -> () {}"),
              Example("let foo: (Int) -> ()"),
              Example("func foo() -> ()?"),
              Example("func foo() -> ()!"),
              Example("func foo() -> Void?"),
              Example("func foo() -> Void!"),
              Example(
                """
                struct A {
                    subscript(key: String) {
                        print(key)
                    }
                }
                """,
              ),
              Example(
                """
                doSomething { arg -> Void in
                    print(arg)
                }
                """, configuration: ["include_closures": false],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("func foo()↓ -> Void {}"),
              Example(
                """
                protocol Foo {
                  func foo()↓ -> Void
                }
                """,
              ),
              Example("func foo()↓ -> () {}"),
              Example("func foo()↓ -> ( ) {}"),
              Example(
                """
                protocol Foo {
                  func foo()↓ -> ()
                }
                """,
              ),
              Example(
                """
                doSomething { arg↓ -> () in
                    print(arg)
                }
                """,
              ),
              Example(
                """
                doSomething { arg↓ -> Void in
                    print(arg)
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("func foo()↓ -> Void {}"): Example("func foo() {}"),
              Example("protocol Foo {\n func foo()↓ -> Void\n}"): Example(
                "protocol Foo {\n func foo()\n}",
              ),
              Example("func foo()↓ -> () {}"): Example("func foo() {}"),
              Example("protocol Foo {\n func foo()↓ -> ()\n}"): Example(
                "protocol Foo {\n func foo()\n}",
              ),
              Example("protocol Foo {\n    #if true\n    func foo()↓ -> Void\n    #endif\n}"):
                Example("protocol Foo {\n    #if true\n    func foo()\n    #endif\n}"),
            ]
    }
}
