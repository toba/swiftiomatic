import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ColonRuleTests {
  @Test func colonWithFlexibleRightSpace() async {
    // Verify Colon rule with test values for when flexible_right_spacing
    // is true.
    let nonTriggeringExamples =
      TestExamples(from: ColonRule.self).nonTriggeringExamples + [
        Example("let abc:  Void\n"),
        Example("let abc:  (Void, String, Int)\n"),
        Example("let abc:  ([Void], String, Int)\n"),
        Example("let abc:  [([Void], String, Int)]\n"),
        Example("func abc(def:  Void) {}\n"),
        Example("let abc = [Void:  Void]()\n"),
      ]
    let triggeringExamples: [Example] = [
      Example("let abc↓:Void\n"),
      Example("let abc↓ :Void\n"),
      Example("let abc↓ : Void\n"),
      Example("let abc↓ : [Void: Void]\n"),
      Example("let abc↓ : (Void, String, Int)\n"),
      Example("let abc↓ : ([Void], String, Int)\n"),
      Example("let abc↓ : [([Void], String, Int)]\n"),
      Example("let abc↓ :String=\"def\"\n"),
      Example("let abc↓ :Int=0\n"),
      Example("let abc↓ :Int = 0\n"),
      Example("let abc↓:Int=0\n"),
      Example("let abc↓:Int = 0\n"),
      Example("let abc↓:Enum=Enum.Value\n"),
      Example("func abc(def↓:Void) {}\n"),
      Example("func abc(def↓ :Void) {}\n"),
      Example("func abc(def↓ : Void) {}\n"),
      Example("func abc(def: Void, ghi↓ :Void) {}\n"),
      Example("let abc = [Void↓:Void]()\n"),
      Example("let abc = [Void↓ : Void]()\n"),
      Example("let abc = [Void↓ :  Void]()\n"),
      Example("let abc = [1: [3↓ : 2], 3: 4]\n"),
      Example("let abc = [1: [3↓ : 2], 3:  4]\n"),
    ]
    let corrections: [Example: Example] = [
      Example("let abc↓:Void\n"): Example("let abc: Void\n"),
      Example("let abc↓ :Void\n"): Example("let abc: Void\n"),
      Example("let abc↓ : Void\n"): Example("let abc: Void\n"),
      Example("let abc↓ : [Void: Void]\n"): Example("let abc: [Void: Void]\n"),
      Example("let abc↓ : (Void, String, Int)\n"): Example("let abc: (Void, String, Int)\n"),
      Example("let abc↓ : ([Void], String, Int)\n"): Example(
        "let abc: ([Void], String, Int)\n",
      ),
      Example("let abc↓ : [([Void], String, Int)]\n"): Example(
        "let abc: [([Void], String, Int)]\n",
      ),
      Example("let abc↓ :String=\"def\"\n"): Example("let abc: String=\"def\"\n"),
      Example("let abc↓ :Int=0\n"): Example("let abc: Int=0\n"),
      Example("let abc↓ :Int = 0\n"): Example("let abc: Int = 0\n"),
      Example("let abc↓:Int=0\n"): Example("let abc: Int=0\n"),
      Example("let abc↓:Int = 0\n"): Example("let abc: Int = 0\n"),
      Example("let abc↓:Enum=Enum.Value\n"): Example("let abc: Enum=Enum.Value\n"),
      Example("func abc(def↓:Void) {}\n"): Example("func abc(def: Void) {}\n"),
      Example("func abc(def↓ :Void) {}\n"): Example("func abc(def: Void) {}\n"),
      Example("func abc(def↓ : Void) {}\n"): Example("func abc(def: Void) {}\n"),
      Example("func abc(def: Void, ghi↓ :Void) {}\n"): Example(
        "func abc(def: Void, ghi: Void) {}\n",
      ),
      Example("let abc = [Void↓:Void]()\n"): Example("let abc = [Void: Void]()\n"),
      Example("let abc = [Void↓ : Void]()\n"): Example("let abc = [Void: Void]()\n"),
      Example("let abc = [Void↓ :  Void]()\n"): Example("let abc = [Void: Void]()\n"),
      Example("let abc = [1: [3↓ : 2], 3: 4]\n"): Example("let abc = [1: [3: 2], 3: 4]\n"),
      Example("let abc = [1: [3↓ : 2], 3:  4]\n"): Example("let abc = [1: [3: 2], 3:  4]\n"),
    ]
    let description = TestExamples(from: ColonRule.self)
      .with(nonTriggeringExamples: nonTriggeringExamples, triggeringExamples: triggeringExamples, corrections: corrections)

    await verifyRule(description, ruleConfiguration: ["flexible_right_spacing": true])
  }

  @Test func colonWithoutApplyToDictionaries() async {
    let nonTriggeringExamples =
      TestExamples(from: ColonRule.self).nonTriggeringExamples + [
        Example("let abc = [Void:Void]()\n"),
        Example("let abc = [Void : Void]()\n"),
        Example("let abc = [Void:  Void]()\n"),
        Example("let abc = [Void :  Void]()\n"),
        Example("let abc = [1: [3 : 2], 3: 4]\n"),
        Example("let abc = [1: [3 : 2], 3:  4]\n"),
      ]
    let triggeringExamples: [Example] = [
      Example("let abc↓:Void\n"),
      Example("let abc↓:  Void\n"),
      Example("let abc↓ :Void\n"),
      Example("let abc↓ : Void\n"),
      Example("let abc↓ : [Void: Void]\n"),
      Example("let abc↓ : (Void, String, Int)\n"),
      Example("let abc↓ : ([Void], String, Int)\n"),
      Example("let abc↓ : [([Void], String, Int)]\n"),
      Example("let abc↓:  (Void, String, Int)\n"),
      Example("let abc↓:  ([Void], String, Int)\n"),
      Example("let abc↓:  [([Void], String, Int)]\n"),
      Example("let abc↓ :String=\"def\"\n"),
      Example("let abc↓ :Int=0\n"),
      Example("let abc↓ :Int = 0\n"),
      Example("let abc↓:Int=0\n"),
      Example("let abc↓:Int = 0\n"),
      Example("let abc↓:Enum=Enum.Value\n"),
      Example("func abc(def↓:Void) {}\n"),
      Example("func abc(def↓:  Void) {}\n"),
      Example("func abc(def↓ :Void) {}\n"),
      Example("func abc(def↓ : Void) {}\n"),
      Example("func abc(def: Void, ghi↓ :Void) {}\n"),
    ]
    let corrections: [Example: Example] = [
      Example("let abc↓:Void\n"): Example("let abc: Void\n"),
      Example("let abc↓:  Void\n"): Example("let abc: Void\n"),
      Example("let abc↓ :Void\n"): Example("let abc: Void\n"),
      Example("let abc↓ : Void\n"): Example("let abc: Void\n"),
      Example("let abc↓ : [Void: Void]\n"): Example("let abc: [Void: Void]\n"),
      Example("let abc↓ : (Void, String, Int)\n"): Example("let abc: (Void, String, Int)\n"),
      Example("let abc↓ : ([Void], String, Int)\n"): Example(
        "let abc: ([Void], String, Int)\n",
      ),
      Example("let abc↓ : [([Void], String, Int)]\n"): Example(
        "let abc: [([Void], String, Int)]\n",
      ),
      Example("let abc↓:  (Void, String, Int)\n"): Example("let abc: (Void, String, Int)\n"),
      Example("let abc↓:  ([Void], String, Int)\n"): Example(
        "let abc: ([Void], String, Int)\n",
      ),
      Example("let abc↓:  [([Void], String, Int)]\n"): Example(
        "let abc: [([Void], String, Int)]\n",
      ),
      Example("let abc↓ :String=\"def\"\n"): Example("let abc: String=\"def\"\n"),
      Example("let abc↓ :Int=0\n"): Example("let abc: Int=0\n"),
      Example("let abc↓ :Int = 0\n"): Example("let abc: Int = 0\n"),
      Example("let abc↓:Int=0\n"): Example("let abc: Int=0\n"),
      Example("let abc↓:Int = 0\n"): Example("let abc: Int = 0\n"),
      Example("let abc↓:Enum=Enum.Value\n"): Example("let abc: Enum=Enum.Value\n"),
      Example("func abc(def↓:Void) {}\n"): Example("func abc(def: Void) {}\n"),
      Example("func abc(def↓:  Void) {}\n"): Example("func abc(def: Void) {}\n"),
      Example("func abc(def↓ :Void) {}\n"): Example("func abc(def: Void) {}\n"),
      Example("func abc(def↓ : Void) {}\n"): Example("func abc(def: Void) {}\n"),
      Example("func abc(def: Void, ghi↓ :Void) {}\n"): Example(
        "func abc(def: Void, ghi: Void) {}\n",
      ),
    ]

    let description = TestExamples(from: ColonRule.self)
      .with(nonTriggeringExamples: nonTriggeringExamples, triggeringExamples: triggeringExamples, corrections: corrections)

    await verifyRule(description, ruleConfiguration: ["apply_to_dictionaries": false])
  }
}
