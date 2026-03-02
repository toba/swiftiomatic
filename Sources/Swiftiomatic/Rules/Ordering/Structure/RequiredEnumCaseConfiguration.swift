struct RequiredEnumCaseConfiguration: RuleConfiguration {
    private static let exampleConfiguration = [
        "NetworkResponsable": ["success": "warning", "error": "warning", "notConnected": "warning"]
    ]
    let id = "required_enum_case"
    let name = "Required Enum Case"
    let summary = "Enums conforming to a specified protocol must implement a specific case(s)."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                enum MyNetworkResponse: String, NetworkResponsable {
                    case success, error, notConnected
                }
                """, configuration: Self.exampleConfiguration,
              ),
              Example(
                """
                enum MyNetworkResponse: String, NetworkResponsable {
                    case success, error, notConnected(error: Error)
                }
                """, configuration: Self.exampleConfiguration,
              ),
              Example(
                """
                enum MyNetworkResponse: String, NetworkResponsable {
                    case success
                    case error
                    case notConnected
                }
                """, configuration: Self.exampleConfiguration,
              ),
              Example(
                """
                enum MyNetworkResponse: String, NetworkResponsable {
                    case success
                    case error
                    case notConnected(error: Error)
                }
                """, configuration: Self.exampleConfiguration,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓enum MyNetworkResponse: String, NetworkResponsable {
                    case success, error
                }
                """, configuration: Self.exampleConfiguration,
              ),
              Example(
                """
                ↓enum MyNetworkResponse: String, NetworkResponsable {
                    case success, error
                }
                """, configuration: Self.exampleConfiguration,
              ),
              Example(
                """
                ↓enum MyNetworkResponse: String, NetworkResponsable {
                    case success
                    case error
                }
                """, configuration: Self.exampleConfiguration,
              ),
              Example(
                """
                ↓enum MyNetworkResponse: String, NetworkResponsable {
                    case success
                    case error
                }
                """, configuration: Self.exampleConfiguration,
              ),
            ]
    }
}
