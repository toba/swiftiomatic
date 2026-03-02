struct VoidFunctionInTernaryConditionConfiguration: RuleConfiguration {
    let id = "void_function_in_ternary"
    let name = "Void Function in Ternary"
    let summary = "Using ternary to call Void functions should be avoided"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                if success {
                    askQuestion()
                } else {
                    exit()
                }
                """,
              ),
              Example(
                """
                var price: Double {
                    return hasDiscount ? calculatePriceWithDiscount() : calculateRegularPrice()
                }
                """,
              ),
              Example("foo(x == 2 ? a() : b())"),
              Example(
                """
                chevronView.image = collapsed ? .icon(.mediumChevronDown) : .icon(.mediumChevronUp)
                """,
              ),
              Example(
                """
                array.map { elem in
                    elem.isEmpty() ? .emptyValue() : .number(elem)
                }
                """,
              ),
              Example(
                """
                func compute(data: [Int]) -> Int {
                    data.isEmpty ? 0 : expensiveComputation(data)
                }
                """,
              ),
              Example(
                """
                var value: Int {
                    mode == .fast ? fastComputation() : expensiveComputation()
                }
                """,
              ),
              Example(
                """
                var value: Int {
                    get {
                        mode == .fast ? fastComputation() : expensiveComputation()
                    }
                }
                """,
              ),
              Example(
                """
                subscript(index: Int) -> Int {
                    get {
                        index == 0 ? defaultValue() : compute(index)
                    }
                """,
              ),
              Example(
                """
                subscript(index: Int) -> Int {
                    index == 0 ? defaultValue() : compute(index)
                """,
              ),
              Example(
                """
                var a = b ? c() : d()
                a += b ? c() : d()
                a -= b ? c() : d()
                a *= b ? c() : d()
                a &<<= b ? c() : d()
                a &-= b ? c() : d()
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("success ↓? askQuestion() : exit()"),
              Example(
                """
                perform { elem in
                    elem.isEmpty() ↓? .emptyValue() : .number(elem)
                    return 1
                }
                """,
              ),
              Example(
                """
                DispatchQueue.main.async {
                    self.sectionViewModels[section].collapsed.toggle()
                    self.sectionViewModels[section].collapsed
                        ↓? self.tableView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
                        : self.tableView.insertRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
                    self.tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: section), at: .top, animated: true)
                }
                """,
              ),
              Example(
                """
                subscript(index: Int) -> Int {
                    index == 0 ↓? something() : somethingElse(index)
                    return index
                """,
              ),
              Example(
                """
                var value: Int {
                    mode == .fast ↓? something() : somethingElse()
                    return 0
                }
                """,
              ),
              Example(
                """
                var value: Int {
                    get {
                        mode == .fast ↓? something() : somethingElse()
                        return 0
                    }
                }
                """,
              ),
              Example(
                """
                subscript(index: Int) -> Int {
                    get {
                        index == 0 ↓? something() : somethingElse(index)
                        return index
                    }
                """,
              ),
            ]
    }
}
