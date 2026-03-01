import Testing
@testable import Swiftiomatic

@Suite struct EmptyBracesTests {
    @Test func linebreaksRemovedInsideBraces() {
        let input = """
        func foo() {

         }
        """
        let output = """
        func foo() {}
        """
        testFormatting(for: input, output, rule: .emptyBraces)
    }

    @Test func commentNotRemovedInsideBraces() {
        let input = """
        func foo() { // foo
        }
        """
        testFormatting(for: input, rule: .emptyBraces)
    }

    @Test func emptyBracesNotRemovedInDoCatch() {
        let input = """
        do {
        } catch is FooError {
        } catch {}
        """
        testFormatting(for: input, rule: .emptyBraces)
    }

    @Test func emptyBracesNotRemovedInIfElse() {
        let input = """
        if bar {
        } else if foo {
        } else {}
        """
        testFormatting(for: input, rule: .emptyBraces)
    }

    @Test func spaceRemovedInsideEmptybraces() {
        let input = """
        foo { }
        """
        let output = """
        foo {}
        """
        testFormatting(for: input, output, rule: .emptyBraces)
    }

    @Test func spaceAddedInsideEmptyBracesWithSpacedConfiguration() {
        let input = """
        foo {}
        """
        let output = """
        foo { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, output, rule: .emptyBraces, options: options)
    }

    @Test func linebreaksRemovedInsideBracesWithSpacedConfiguration() {
        let input = """
        func foo() {

         }
        """
        let output = """
        func foo() { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, output, rule: .emptyBraces, options: options)
    }

    @Test func commentNotRemovedInsideBracesWithSpacedConfiguration() {
        let input = """
        func foo() { // foo
        }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    @Test func emptyBracesSpaceNotRemovedInDoCatchWithSpacedConfiguration() {
        let input = """
        do {
        } catch is FooError {
        } catch { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    @Test func emptyBracesSpaceNotRemovedInIfElseWithSpacedConfiguration() {
        let input = """
        if bar {
        } else if foo {
        } else { }
        """
        let options = FormatOptions(emptyBracesSpacing: .spaced)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    @Test func emptyBracesLinebreakNotRemovedInIfElseWithLinebreakConfiguration() {
        let input = """
        if bar {
        } else if foo {
        } else {
        }
        """
        let options = FormatOptions(emptyBracesSpacing: .linebreak)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }

    @Test func emptyBracesLinebreakIndentedCorrectly() {
        let input = """
        func foo() {
            if bar {
            } else if foo {
            } else {
            }
        }
        """
        let options = FormatOptions(emptyBracesSpacing: .linebreak)
        testFormatting(for: input, rule: .emptyBraces, options: options)
    }
}
