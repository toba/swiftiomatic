struct XCTFailMessageConfiguration: RuleConfiguration {
    let id = "xctfail_message"
    let name = "XCTFail Message"
    let summary = "An XCTFail call should include a description of the assertion"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func testFoo() {
                  XCTFail("bar")
                }
                """,
              ),
              Example(
                """
                func testFoo() {
                  XCTFail(bar)
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func testFoo() {
                  ↓XCTFail()
                }
                """,
              ),
              Example(
                """
                func testFoo() {
                  ↓XCTFail("")
                }
                """,
              ),
            ]
    }
}
