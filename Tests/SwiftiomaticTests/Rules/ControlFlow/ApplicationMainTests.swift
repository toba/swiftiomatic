import Testing
@testable import Swiftiomatic

@Suite struct ApplicationMainTests {
    @Test func uIApplicationMainReplacedByMain() {
        let input = """
        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {}
        """
        let output = """
        @main
        class AppDelegate: UIResponder, UIApplicationDelegate {}
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .applicationMain, options: options)
    }

    @Test func nSApplicationMainReplacedByMain() {
        let input = """
        @NSApplicationMain
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """
        let output = """
        @main
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .applicationMain, options: options)
    }

    @Test func nSApplicationMainNotReplacedInSwift5_2() {
        let input = """
        @NSApplicationMain
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .applicationMain, options: options)
    }
}
