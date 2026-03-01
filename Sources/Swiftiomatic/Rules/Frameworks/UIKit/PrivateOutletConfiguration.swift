struct PrivateOutletConfiguration: RuleConfiguration {
    let id = "private_outlet"
    let name = "Private Outlets"
    let summary = "IBOutlets should be private to avoid leaking UIKit to higher layers"
    let isOptIn = true
}
