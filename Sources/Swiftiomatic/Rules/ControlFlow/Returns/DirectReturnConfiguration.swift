struct DirectReturnConfiguration: RuleConfiguration {
    let id = "direct_return"
    let name = "Direct Return"
    let summary = "Directly return the expression instead of assigning it to a variable first"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func f() -> Int {
                    let b = 2
                    let a = 1
                    return b
                }
                """,
              ),
              Example(
                """
                struct S {
                    var a: Int {
                        var b = 1
                        b = 2
                        return b
                    }
                }
                """,
              ),
              Example(
                """
                func f() -> Int {
                    let b = 2
                    f()
                    return b
                }
                """,
              ),
              Example(
                """
                func f() -> Int {
                    { i in
                        let b = 2
                        return i
                    }(1)
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func f() -> Int {
                    let ↓b = 2
                    return b
                }
                """,
              ),
              Example(
                """
                struct S {
                    var a: Int {
                        var ↓b = 1
                        // comment
                        return b
                    }
                }
                """,
              ),
              Example(
                """
                func f() -> Bool {
                    let a = 1, ↓b = true
                    return b
                }
                """,
              ),
              Example(
                """
                func f() -> Int {
                    { _ in
                        let ↓b = 2
                        return b
                    }(1)
                }
                """,
              ),
              Example(
                """
                func f(i: Int) -> Int {
                    if i > 1 {
                        let ↓a = 2
                        return a
                    } else {
                        let ↓b = 2, a = 1
                        return b
                    }
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                func f() -> Int {
                    let b = 2
                    return b
                }
                """,
              ): Example(
                """
                func f() -> Int {
                    return 2
                }
                """,
              ),
              Example(
                """
                struct S {
                    var a: Int {
                        var b = 2 > 1
                            ? f()
                            : 1_000
                        // comment
                        return b
                    }
                    func f() -> Int { 1 }
                }
                """,
              ): Example(
                """
                struct S {
                    var a: Int {
                        // comment
                        return 2 > 1
                            ? f()
                            : 1_000
                    }
                    func f() -> Int { 1 }
                }
                """,
              ),
              Example(
                """
                func f() -> Bool {
                    let a = 1, b = true
                    return b
                }
                """,
              ): Example(
                """
                func f() -> Bool {
                    let a = 1
                    return true
                }
                """,
              ),
              Example(
                """
                func f() -> Int {
                    { _ in
                        // A comment
                        let b = 2
                        // Another comment
                        return b
                    }(1)
                }
                """,
              ): Example(
                """
                func f() -> Int {
                    { _ in
                        // A comment
                        // Another comment
                        return 2
                    }(1)
                }
                """,
              ),
              Example(
                """
                func f() -> UIView {
                    let view = instantiateView() as! UIView // sm:disable:this force_cast
                    return view
                }
                """,
              ): Example(
                """
                func f() -> UIView {
                    return instantiateView() as! UIView // sm:disable:this force_cast
                }
                """,
              ),
              Example(
                """
                func f() -> UIView {
                    let view = instantiateView() as! UIView // sm:disable:this force_cast
                    return view // return the view
                }
                """,
              ): Example(
                """
                func f() -> UIView {
                    return instantiateView() as! UIView // sm:disable:this force_cast // return the view
                }
                """,
              ),
              Example(
                """
                func f() -> Bool {
                    let b  :  Bool  =  true
                    return b
                }
                """,
              ): Example(
                """
                func f() -> Bool {
                    return true as Bool
                }
                """,
              ),
            ]
    }
}
