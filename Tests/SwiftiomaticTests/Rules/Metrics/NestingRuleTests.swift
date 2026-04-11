import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct NestingRuleTests {
  // MARK: - Configuration: always_allow_one_type_in_functions

  // When enabled, one nested type inside a function does not count toward the type nesting limit.
  // This means type > type > func > type is allowed (the type inside the func gets a free pass).

  @Test func oneTypeInFunctionAllowedWhenConfigured() async {
    // struct > struct > func > struct -- the innermost struct gets the free pass
    await assertNoViolation(
      NestingRule.self,
      """
      struct Example_0 {
          struct Example_1 {
              func f_0() {
                  struct Example_2 {}
              }
          }
      }
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  @Test func typeInFuncInTypeInFuncAllowedWhenConfigured() async {
    // Alternating type/func nesting: each function resets the "one free type" allowance
    await assertNoViolation(
      NestingRule.self,
      """
      class Example_0 {
          class Example_1 {
              func f_0() {
                  class Example_2 {
                      func f_1() {
                          class Example_3 {}
                      }
                  }
              }
          }
      }
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  @Test func funcWithNestedTypeAndTypeAllowedWhenConfigured() async {
    await assertNoViolation(
      NestingRule.self,
      """
      func f_0() {
          enum Example_0 {
              enum Example_1 {}
          }
      }
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  @Test func closureWithTypesAllowedWhenConfigured() async {
    await assertNoViolation(
      NestingRule.self,
      """
      exampleFunc(closure: {
          actor Example_0 {
              actor Example_1 {
                  func f_0() {
                     actor Example_2 {}
                 }
             }
         }
         func f_0() {
             actor Example_0 {
                 func f_1() {
                     actor Example_1 {
                         func f_2() {
                             actor Example_2 {}
                         }
                     }
                 }
             }
         }
      })
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  @Test func switchWithTypesAllowedWhenConfigured() async {
    await assertNoViolation(
      NestingRule.self,
      """
      switch example {
      case .exampleCase:
         struct Example_0 {
             struct Example_1 {
                 func f_0() {
                     struct Example_2 {}
                 }
             }
         }
      default:
         func f_0() {
             struct Example_0 {
                 func f_1() {
                     struct Example_1 {
                         func f_2() {
                             struct Example_2 {}
                         }
                     }
                 }
             }
         }
      }
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  @Test func secondTypeInFunctionViolatesWhenConfigured() async {
    // type > type > func > type > type -- the second type inside func exceeds the allowance
    await assertViolates(
      NestingRule.self,
      """
      struct Example_0 {
         struct Example_1 {
             func f_0() {
                 struct Example_2 {
                     struct Example_3 {}
                 }
             }
         }
      }
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  @Test func deepAlternatingNestingViolatesWhenConfigured() async {
    await assertViolates(
      NestingRule.self,
      """
      enum Example_0 {
         enum Example_1 {
             func f_0() {
                 enum Example_2 {
                     func f_1() {
                         enum Example_3 {
                             enum Example_4 {}
                         }
                     }
                 }
             }
         }
      }
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  @Test func funcWithThreeNestedTypesViolatesWhenConfigured() async {
    await assertViolates(
      NestingRule.self,
      """
      func f_0() {
         class Example_0 {
             class Example_1 {
                 class Example_2 {}
             }
         }
      }
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  @Test func ifBranchStillCountsComplexity() async {
    // 11 if-branches exceed complexity
    await assertViolates(
      NestingRule.self,
      """
      exampleFunc(closure: {
         actor Example_0 {
             actor Example_1 {
                 func f_0() {
                     actor Example_2 {
                         actor Example_3 {}
                     }
                 }
             }
         }
         func f_0() {
             actor Example_0 {
                 func f_1() {
                     actor Example_1 {
                         func f_2() {
                             actor Example_2 {
                                 actor Example_3 {}
                             }
                         }
                     }
                 }
             }
         }
      })
      """,
      configuration: ["always_allow_one_type_in_functions": true])
  }

  // MARK: - Configuration: check_nesting_in_closures_and_statements = false

  // When disabled, closures and statement bodies (switch, for, while, if, etc.)
  // do NOT count toward nesting depth.

  @Test func deepNestingInClosureAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      exampleFunc(closure: {
         struct Example_0 {
             struct Example_1 {
                 struct Example_2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func deepNestingInSwitchAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      switch example {
      case .exampleCase:
         class Example_0 {
             class Example_1 {
                 class Example 2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func deepNestingInForLoopAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      for i in indicies {
         enum Example_0 {
             enum Example_1 {
                 enum Example 2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func deepNestingInWhileLoopAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      while true {
         actor Example_0 {
             actor Example_1 {
                 actor Example 2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func deepNestingInRepeatAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      repeat {
         struct Example_0 {
             struct Example_1 {
                 struct Example 2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func deepNestingInIfAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      if flag {
         class Example_0 {
             class Example_1 {
                 class Example 2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func deepNestingInGuardAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      guard flag else {
         enum Example_0 {
             enum Example_1 {
                 enum Example 2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func deepNestingInDeferAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      defer {
         actor Example_0 {
             actor Example_1 {
                 actor Example 2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func deepNestingInDoCatchAllowedWhenCheckDisabled() async {
    await assertNoViolation(
      NestingRule.self,
      """
      do {
         struct Example_0 {
             struct Example_1 {
                 struct Example 2 {}
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
         struct Example_0 {
             struct Example_1 {
                 struct Example 2 {}
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
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  // Even with closures/statements disabled, direct type/function nesting still triggers

  @Test func typeNestingStillTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      struct Example_0 {
          struct Example_1 {
              struct Example_2 {}
          }
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func computedPropertyTypeNestingTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      var example: Int {
         class Example_0 {
             class Example_1 {
                 class Example_2 {}
             }
         }
         return 5
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func didSetTypeNestingTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      var example: Int = 5 {
         didSet {
             enum Example_0 {
                 enum Example_1 {
                     enum Example_2 {}
                 }
             }
         }
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func extensionTypeNestingTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      extension Example_0 {
         actor Example_1 {
             actor Example_2 {}
         }
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func functionNestingTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      func f_0() {
         func f_1() {
             func f_2() {
                 func f_3() {}
             }
         }
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func computedPropertyFuncNestingTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      var example: Int {
         func f_0() {
             func f_1() {
                 func f_2() {
                     func f_3() {}
                 }
             }
         }
         return 5
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func didSetFuncNestingTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      var example: Int = 5 {
         didSet {
             func f_0() {
                 func f_1() {
                     func f_2() {
                         func f_3() {}
                     }
                 }
             }
         }
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func extensionFuncNestingTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      extension Example_0 {
         func f_0() {
             func f_1() {
                 func f_2() {
                     func f_3() {}
                 }
             }
         }
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  @Test func mixedNestingInFuncTriggersWhenClosuresDisabled() async {
    await assertViolates(
      NestingRule.self,
      """
      struct Example_0 {
         func f_0() {
             struct Example_1 {
                 func f_1() {
                     func f_2() {
                         struct Example_2 {}
                         func f_3() {}
                     }
                 }
             }
         }
      }
      """,
      configuration: ["check_nesting_in_closures_and_statements": false])
  }

  // MARK: - Configuration: ignore_typealiases_and_associatedtypes

  @Test func typealiasInNestedTypeAllowedWhenConfigured() async {
    await assertNoViolation(
      NestingRule.self,
      """
      struct Example_0 {
          struct Example_1 {
              typealias Example_2_Type = Example_2.Type
          }
          struct Example_2 {}
      }
      """,
      configuration: ["ignore_typealiases_and_associatedtypes": true])
  }

  @Test func associatedTypeConformanceAllowedWhenConfigured() async {
    await assertNoViolation(
      NestingRule.self,
      """
      protocol Example_Protcol {
          associatedtype AssociatedType
      }

      class Example_1 {
          class Example_2: Example_Protcol {
              typealias AssociatedType = Int
          }
      }
      """,
      configuration: ["ignore_typealiases_and_associatedtypes": true])
  }

  @Test func multipleTypealiasAndAssociatedTypeAllowedWhenConfigured() async {
    await assertNoViolation(
      NestingRule.self,
      """
      protocol Example_Protcol {
          associatedtype AssociatedType
      }

      enum Example_1 {
          enum Example_2: SomeProtcol {
              typealias Example_2_Type = Example_2.Type
          }
          enum Example_3: Example_Protcol {
              typealias AssociatedType = Int
          }
      }
      """,
      configuration: ["ignore_typealiases_and_associatedtypes": true])
  }
}
