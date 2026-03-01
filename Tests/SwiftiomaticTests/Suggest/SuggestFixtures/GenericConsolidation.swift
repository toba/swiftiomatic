// Fixture: generic consolidation patterns

// Should flag: any Protocol in parameter position
func process(items: any Collection) {
    for item in items { _ = item }
}

// Should NOT flag: some Protocol (already good)
func processGood(items: some Sequence) {
    for item in items { _ = item }
}

// Should flag: any Protocol in local variable
func example() {
    let handler: any Hashable = 42
    _ = handler
}

// Should flag: some Collection over-constrained (only Sequence ops used)
func iterate(over items: some Collection<Int>) {
    for item in items {
        print(item)
    }
}

// Should NOT flag: uses Collection-specific operations
func indexAccess(items: some Collection<Int>) {
    print(items[items.startIndex])
    print(items.count)
}
