import Testing
@testable import Swiftiomatic

@Suite struct EnumAssociableTests {
    // MARK: associatedValue

    private enum TestEnum: EnumAssociable {
        case nothing
        case string(String)
        case optionalString(String?)
        case intTuple(first: Int, second: Int?)
        case closure((Bool) -> Bool) // this case don't work properly
    }

    @Test func string() {
        let input = TestEnum.string("b")
        #expect(input.associatedValue() == "b")
    }

    @Test func optionalString() {
        let input = TestEnum.optionalString("D")
        #expect(input.associatedValue() == "D")
    }

    @Test(.disabled("Swift runtime SIGSEGV in generic metadata resolution (ClosedRange<>.Index)"))
    func nilOptionalString() {
        let input = TestEnum.optionalString(nil)
        #expect(input.associatedValue() == nil)
    }

    @Test func tuple() {
        let input = TestEnum.intTuple(first: 3, second: nil)
        let result: (Int?, Int?) = input.associatedValue()
        #expect(result.0 == 3)
        #expect(result.1 == nil)
    }

    @Test func nothingAsAnyOptional() {
        // not able to make this work
        let input = TestEnum.nothing
        let result: String? = input.associatedValue()
        #expect(result == nil)
    }

    // MARK: Not testable

    //    struct MyStruct: EnumAssociable {
    //        let name: String
    //    }
    //
    //    @Test func crashIfValueIsStruct() {
    //        //  precondition is not testable
    //        let input = MyStruct(name: "name")
    //        #expect(input.associatedValue( != nil)) // Crashes
    //    }
    //
    //    @Test func crashIfValueIsClosure() {
    //        let input = TestEnum.closure { return $0 == true }
    //        let result: (Bool) -> Bool = input.associatedValue()
    //        XCTAssertTrue(result(true)) // Crashes
    //    }
}
