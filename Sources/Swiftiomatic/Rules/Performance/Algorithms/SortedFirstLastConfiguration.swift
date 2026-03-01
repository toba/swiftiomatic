struct SortedFirstLastConfiguration: RuleConfiguration {
    let id = "sorted_first_last"
    let name = "Min or Max over Sorted First or Last"
    let summary = "Prefer using `min()` or `max()` over `sorted().first` or `sorted().last`"
    let isOptIn = true
}
