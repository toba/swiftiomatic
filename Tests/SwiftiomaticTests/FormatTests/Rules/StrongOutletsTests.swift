import Testing
@testable import Swiftiomatic

@Suite struct StrongOutletsTests {
    @Test func removeWeakFromOutlet() {
        let input = """
        @IBOutlet weak var label: UILabel!
        """
        let output = """
        @IBOutlet var label: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    @Test func removeWeakFromPrivateOutlet() {
        let input = """
        @IBOutlet private weak var label: UILabel!
        """
        let output = """
        @IBOutlet private var label: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    @Test func removeWeakFromOutletOnSplitLine() {
        let input = """
        @IBOutlet
        weak var label: UILabel!
        """
        let output = """
        @IBOutlet
        var label: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    @Test func noRemoveWeakFromNonOutlet() {
        let input = """
        weak var label: UILabel!
        """
        testFormatting(for: input, rule: .strongOutlets)
    }

    @Test func noRemoveWeakFromNonOutletAfterOutlet() {
        let input = """
        @IBOutlet weak var label1: UILabel!
        weak var label2: UILabel!
        """
        let output = """
        @IBOutlet var label1: UILabel!
        weak var label2: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    @Test func noRemoveWeakFromDelegateOutlet() {
        let input = """
        @IBOutlet weak var delegate: UITableViewDelegate?
        """
        testFormatting(for: input, rule: .strongOutlets)
    }

    @Test func noRemoveWeakFromDataSourceOutlet() {
        let input = """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        """
        testFormatting(for: input, rule: .strongOutlets)
    }

    @Test func removeWeakFromOutletAfterDelegateOutlet() {
        let input = """
        @IBOutlet weak var delegate: UITableViewDelegate?
        @IBOutlet weak var label1: UILabel!
        """
        let output = """
        @IBOutlet weak var delegate: UITableViewDelegate?
        @IBOutlet var label1: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }

    @Test func removeWeakFromOutletAfterDataSourceOutlet() {
        let input = """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        @IBOutlet weak var label1: UILabel!
        """
        let output = """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        @IBOutlet var label1: UILabel!
        """
        testFormatting(for: input, output, rule: .strongOutlets)
    }
}
