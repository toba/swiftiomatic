struct NimbleOperatorConfiguration: RuleConfiguration {
    let id = "nimble_operator"
    let name = "Nimble Operator"
    let summary = "Prefer Nimble operator overloads over free matcher functions"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("expect(seagull.squawk) != \"Hi!\""),
              Example("expect(\"Hi!\") == \"Hi!\""),
              Example("expect(10) > 2"),
              Example("expect(10) >= 10"),
              Example("expect(10) < 11"),
              Example("expect(10) <= 10"),
              Example("expect(x) === x"),
              Example("expect(10) == 10"),
              Example("expect(success) == true"),
              Example("expect(value) == nil"),
              Example("expect(value) != nil"),
              Example("expect(object.asyncFunction()).toEventually(equal(1))"),
              Example("expect(actual).to(haveCount(expected))"),
              Example(
                """
                foo.method {
                    expect(value).to(equal(expectedValue), description: "Failed")
                    return Bar(value: ())
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓expect(seagull.squawk).toNot(equal(\"Hi\"))"),
              Example("↓expect(12).toNot(equal(10))"),
              Example("↓expect(10).to(equal(10))"),
              Example("↓expect(10, line: 1).to(equal(10))"),
              Example("↓expect(10).to(beGreaterThan(8))"),
              Example("↓expect(10).to(beGreaterThanOrEqualTo(10))"),
              Example("↓expect(10).to(beLessThan(11))"),
              Example("↓expect(10).to(beLessThanOrEqualTo(10))"),
              Example("↓expect(x).to(beIdenticalTo(x))"),
              Example("↓expect(success).to(beTrue())"),
              Example("↓expect(success).to(beFalse())"),
              Example("↓expect(value).to(beNil())"),
              Example("↓expect(value).toNot(beNil())"),
              Example("expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓expect(seagull.squawk).toNot(equal(\"Hi\"))"): Example(
                "expect(seagull.squawk) != \"Hi\"",
              ),
              Example("↓expect(\"Hi!\").to(equal(\"Hi!\"))"): Example("expect(\"Hi!\") == \"Hi!\""),
              Example("↓expect(12).toNot(equal(10))"): Example("expect(12) != 10"),
              Example("↓expect(value1).to(equal(value2))"): Example("expect(value1) == value2"),
              Example("↓expect(   value1  ).to(equal(  value2.foo))"): Example(
                "expect(   value1  ) == value2.foo",
              ),
              Example("↓expect(value1).to(equal(10))"): Example("expect(value1) == 10"),
              Example("↓expect(10).to(beGreaterThan(8))"): Example("expect(10) > 8"),
              Example("↓expect(10).to(beGreaterThanOrEqualTo(10))"): Example("expect(10) >= 10"),
              Example("↓expect(10).to(beLessThan(11))"): Example("expect(10) < 11"),
              Example("↓expect(10).to(beLessThanOrEqualTo(10))"): Example("expect(10) <= 10"),
              Example("↓expect(x).to(beIdenticalTo(x))"): Example("expect(x) === x"),
              Example("↓expect(success).to(beTrue())"): Example("expect(success) == true"),
              Example("↓expect(success).to(beFalse())"): Example("expect(success) == false"),
              Example("↓expect(success).toNot(beFalse())"): Example("expect(success) != false"),
              Example("↓expect(success).toNot(beTrue())"): Example("expect(success) != true"),
              Example("↓expect(value).to(beNil())"): Example("expect(value) == nil"),
              Example("↓expect(value).toNot(beNil())"): Example("expect(value) != nil"),
              Example("expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))"): Example(
                "expect(10) > 2\n expect(10) > 2",
              ),
            ]
    }
}
