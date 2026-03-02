struct ExplicitInitConfiguration: RuleConfiguration {
    let id = "explicit_init"
    let name = "Explicit Init"
    let summary = "Explicitly calling .init() should be avoided"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                import Foundation
                class C: NSObject {
                    override init() {
                        super.init()
                    }
                }
                """,
              ),  // super
              Example(
                """
                struct S {
                    let n: Int
                }
                extension S {
                    init() {
                        self.init(n: 1)
                    }
                }
                """,
              ),  // self
              Example(
                """
                [1].flatMap(String.init)
                """,
              ),  // pass init as closure
              Example(
                """
                [String.self].map { $0.init(1) }
                """,
              ),  // initialize from a metatype value
              Example(
                """
                [String.self].map { type in type.init(1) }
                """,
              ),  // initialize from a metatype value
              Example(
                """
                Observable.zip(obs1, obs2, resultSelector: MyType.init).asMaybe()
                """,
              ),
              Example("_ = GleanMetrics.Tabs.someType.init()"),
              Example(
                """
                Observable.zip(
                  obs1,
                  obs2,
                  resultSelector: MyType.init
                ).asMaybe()
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                [1].flatMap{String↓.init($0)}
                """,
              ),
              Example(
                """
                [String.self].map { Type in Type↓.init(1) }
                """,
              ),  // Starting with capital letter assumes a type
              Example(
                """
                func foo() -> [String] {
                    return [1].flatMap { String↓.init($0) }
                }
                """,
              ),
              Example("_ = GleanMetrics.Tabs.GroupedTabExtra↓.init()"),
              Example("_ = Set<KsApi.Category>↓.init()"),
              Example(
                """
                Observable.zip(
                  obs1,
                  obs2,
                  resultSelector: { MyType↓.init($0, $1) }
                ).asMaybe()
                """,
              ),
              Example(
                """
                let int = In🤓t↓
                .init(1.0)
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                let int = Int↓


                .init(1.0)
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                let int = Int↓


                      .init(1.0)
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example(
                """
                [1].flatMap{String↓.init($0)}
                """,
              ):
                Example(
                  """
                  [1].flatMap{String($0)}
                  """,
                ),
              Example(
                """
                func foo() -> [String] {
                    return [1].flatMap { String↓.init($0) }
                }
                """,
              ):
                Example(
                  """
                  func foo() -> [String] {
                      return [1].flatMap { String($0) }
                  }
                  """,
                ),
              Example(
                """
                class C {
                #if true
                    func f() {
                        [1].flatMap{String↓.init($0)}
                    }
                #endif
                }
                """,
              ):
                Example(
                  """
                  class C {
                  #if true
                      func f() {
                          [1].flatMap{String($0)}
                      }
                  #endif
                  }
                  """,
                ),
              Example(
                """
                let int = Int↓
                .init(1.0)
                """,
              ):
                Example(
                  """
                  let int = Int(1.0)
                  """,
                ),
              Example(
                """
                let int = Int↓


                .init(1.0)
                """,
              ):
                Example(
                  """
                  let int = Int(1.0)
                  """,
                ),
              Example(
                """
                let int = Int↓


                      .init(1.0)
                """,
              ):
                Example(
                  """
                  let int = Int(1.0)
                  """,
                ),
              Example(
                """
                let int = Int↓


                      .init(1.0)



                """,
              ):
                Example(
                  """
                  let int = Int(1.0)



                  """,
                ),
              Example(
                """
                f { e in
                    // comment
                    A↓.init(e: e)
                }
                """,
              ):
                Example(
                  """
                  f { e in
                      // comment
                      A(e: e)
                  }
                  """,
                ),
              Example("_ = GleanMetrics.Tabs.GroupedTabExtra↓.init()"):
                Example("_ = GleanMetrics.Tabs.GroupedTabExtra()"),
              Example("_ = Set<KsApi.Category>↓.init()"):
                Example("_ = Set<KsApi.Category>()"),
            ]
    }
}
