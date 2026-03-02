import Testing

@testable import Swiftiomatic

private let detectingTypes = ["actor", "class", "struct", "enum"]

@Suite(.rulesRegistered) struct NestingRuleTests {
  @Test func nestingWithAlwaysAllowOneTypeInFunctions() async {
    let baseExamples = TestExamples(from: NestingRule.self)
    var nonTriggeringExamples = baseExamples.nonTriggeringExamples
    nonTriggeringExamples.append(
      contentsOf: detectingTypes.flatMap { type -> [Example] in
        [
          .init(
            """
                \(type) Example_0 {
                    \(type) Example_1 {
                        func f_0() {
                            \(type) Example_2 {}
                        }
                    }
                }
            """,
          ),

          .init(
            """
                \(type) Example_0 {
                    \(type) Example_1 {
                        func f_0() {
                            \(type) Example_2 {
                                func f_1() {
                                    \(type) Example_3 {}
                                }
                            }
                        }
                    }
                }
            """,
          ),

          .init(
            """
                func f_0() {
                    \(type) Example_0 {
                        \(type) Example_1 {}
                    }
                }
            """,
          ),
        ]
      },
    )
    nonTriggeringExamples.append(
      contentsOf: detectingTypes.flatMap { type -> [Example] in
        [
          .init(
            """
                exampleFunc(closure: {
                    \(type) Example_0 {
                        \(type) Example_1 {
                            func f_0() {
                               \(type) Example_2 {}
                           }
                       }
                   }
                   func f_0() {
                       \(type) Example_0 {
                           func f_1() {
                               \(type) Example_1 {
                                   func f_2() {
                                       \(type) Example_2 {}
                                   }
                               }
                           }
                       }
                   }
                })
            """,
          ),

          .init(
            """
                switch example {
                case .exampleCase:
                   \(type) Example_0 {
                       \(type) Example_1 {
                           func f_0() {
                               \(type) Example_2 {}
                           }
                       }
                   }
                default:
                   func f_0() {
                       \(type) Example_0 {
                           func f_1() {
                               \(type) Example_1 {
                                   func f_2() {
                                       \(type) Example_2 {}
                                   }
                               }
                           }
                       }
                   }
                }
            """,
          ),
        ]
      },
    )

    var triggeringExamples = detectingTypes.flatMap { type -> [Example] in
      [
        .init(
          """
              \(type) Example_0 {
                 \(type) Example_1 {
                     func f_0() {
                         \(type) Example_2 {
                             ↓\(type) Example_3 {}
                         }
                     }
                 }
              }
          """,
        ),

        .init(
          """
              \(type) Example_0 {
                 \(type) Example_1 {
                     func f_0() {
                         \(type) Example_2 {
                             func f_1() {
                                 \(type) Example_3 {
                                     ↓\(type) Example_4 {}
                                 }
                             }
                         }
                     }
                 }
              }
          """,
        ),

        .init(
          """
              func f_0() {
                 \(type) Example_0 {
                     \(type) Example_1 {
                         ↓\(type) Example_2 {}
                     }
                 }
              }
          """,
        ),
      ]
    }

    triggeringExamples.append(
      contentsOf: detectingTypes.flatMap { type -> [Example] in
        [
          .init(
            """
                exampleFunc(closure: {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           func f_0() {
                               \(type) Example_2 {
                                   ↓\(type) Example_3 {}
                               }
                           }
                       }
                   }
                   func f_0() {
                       \(type) Example_0 {
                           func f_1() {
                               \(type) Example_1 {
                                   func f_2() {
                                       \(type) Example_2 {
                                           ↓\(type) Example_3 {}
                                       }
                                   }
                               }
                           }
                       }
                   }
                })
            """,
          ),

          .init(
            """
                switch example {
                case .exampleCase:
                   \(type) Example_0 {
                       \(type) Example_1 {
                           func f_0() {
                               \(type) Example_2 {
                                   ↓\(type) Example_3 {}
                               }
                           }
                       }
                   }
                default:
                   func f_0() {
                       \(type) Example_0 {
                           func f_1() {
                               \(type) Example_1 {
                                   func f_2() {
                                       \(type) Example_2 {
                                           ↓\(type) Example_3 {}
                                       }
                                   }
                               }
                           }
                       }
                   }
                }
            """,
          ),
        ]
      },
    )

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["always_allow_one_type_in_functions": true])
  }

  @Test func nestingWithoutCheckNestingInClosuresAndStatements() async {
    let baseExamples = TestExamples(from: NestingRule.self)
    var nonTriggeringExamples = baseExamples.nonTriggeringExamples
    nonTriggeringExamples.append(
      contentsOf: detectingTypes.flatMap { type -> [Example] in
        [
          .init(
            """
                exampleFunc(closure: {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example_2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                })
            """,
          ),

          .init(
            """
                switch example {
                case .exampleCase:
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                default:
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                }
            """,
          ),

          .init(
            """
                for i in indicies {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                }
            """,
          ),

          .init(
            """
                while true {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                }
            """,
          ),

          .init(
            """
                repeat {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                } while true
            """,
          ),

          .init(
            """
                if flag {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                }
            """,
          ),

          .init(
            """
                guard flag else {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                   return
                }
            """,
          ),

          .init(
            """
                defer {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                }
            """,
          ),

          .init(
            """
                do {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                } catch {
                   \(type) Example_0 {
                       \(type) Example_1 {
                           \(type) Example 2 {}
                       }
                   }
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               func f_3() {}
                           }
                       }
                   }
                }
            """,
          ),
        ]
      },
    )

    var triggeringExamples = detectingTypes.flatMap { type -> [Example] in
      [
        .init(
          """
              \(type) Example_0 {
                  \(type) Example_1 {
                      ↓\(type) Example_2 {}
                  }
              }
          """,
        ),

        .init(
          """
              var example: Int {
                 \(type) Example_0 {
                     \(type) Example_1 {
                         ↓\(type) Example_2 {}
                     }
                 }
                 return 5
              }
          """,
        ),

        .init(
          """
              var example: Int = 5 {
                 didSet {
                     \(type) Example_0 {
                         \(type) Example_1 {
                             ↓\(type) Example_2 {}
                         }
                     }
                 }
              }
          """,
        ),

        .init(
          """
              extension Example_0 {
                 \(type) Example_1 {
                     ↓\(type) Example_2 {}
                 }
              }
          """,
        ),

        .init(
          """
              \(type) Example_0 {
                 func f_0() {
                     \(type) Example_1 {
                         func f_1() {
                             func f_2() {
                                 ↓\(type) Example_2 {}
                                 ↓func f_3() {}
                             }
                         }
                     }
                 }
              }
          """,
        ),
      ]
    }

    triggeringExamples.append(contentsOf: [
      .init(
        """
            func f_0() {
               func f_1() {
                   func f_2() {
                       ↓func f_3() {}
                   }
               }
            }
        """,
      ),

      .init(
        """
            var example: Int {
               func f_0() {
                   func f_1() {
                       func f_2() {
                           ↓func f_3() {}
                       }
                   }
               }
               return 5
            }
        """,
      ),

      .init(
        """
            var example: Int = 5 {
               didSet {
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               ↓func f_3() {}
                           }
                       }
                   }
               }
            }
        """,
      ),

      .init(
        """
            extension Example_0 {
               func f_0() {
                   func f_1() {
                       func f_2() {
                           ↓func f_3() {}
                       }
                   }
               }
            }
        """,
      ),
    ])

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description,
      ruleConfiguration: ["check_nesting_in_closures_and_statements": false],
    )
  }

  @Test func nestingWithoutTypealiasAndAssociatedtype() async {
    let baseExamples = TestExamples(from: NestingRule.self)
    var nonTriggeringExamples = baseExamples.nonTriggeringExamples
    nonTriggeringExamples.append(
      contentsOf: detectingTypes.flatMap { type -> [Example] in
        [
          .init(
            """
                \(type) Example_0 {
                    \(type) Example_1 {
                        typealias Example_2_Type = Example_2.Type
                    }
                    \(type) Example_2 {}
                }
            """,
          ),
          .init(
            """
                protocol Example_Protcol {
                    associatedtype AssociatedType
                }

                \(type) Example_1 {
                    \(type) Example_2: Example_Protcol {
                        typealias AssociatedType = Int
                    }
                }
            """,
          ),
          .init(
            """
                protocol Example_Protcol {
                    associatedtype AssociatedType
                }

                \(type) Example_1 {
                    \(type) Example_2: SomeProtcol {
                        typealias Example_2_Type = Example_2.Type
                    }
                    \(type) Example_3: Example_Protcol {
                        typealias AssociatedType = Int
                    }
                }
            """,
          ),
        ]
      },
    )

    let examples = baseExamples
      .with(nonTriggeringExamples: nonTriggeringExamples)

    await verifyRule(
      examples, ruleConfiguration: ["ignore_typealiases_and_associatedtypes": true])
  }
}
