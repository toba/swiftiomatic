struct NoGroupingExtensionConfiguration: RuleConfiguration {
    let id = "no_grouping_extension"
    let name = "No Grouping Extension"
    let summary = "Extensions shouldn't be used to group code within the same source file"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("protocol Food {}\nextension Food {}"),
              Example("class Apples {}\nextension Oranges {}"),
              Example("class Box<T> {}\nextension Box where T: Vegetable {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("enum Fruit {}\n↓extension Fruit {}"),
              Example("↓extension Tea: Error {}\nstruct Tea {}"),
              Example("class Ham { class Spam {}}\n↓extension Ham.Spam {}"),
              Example("extension External { struct Gotcha {}}\n↓extension External.Gotcha {}"),
            ]
    }
}
