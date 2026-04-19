package enum ConfigurationItem: Sendable {
    case value(any Sendable & Codable)
    case group(ConfigurationGroup.Key, [String: ConfigurationItem])

    //    package init(from decoder: any Decoder) throws {
    //        let container = try decoder.singleValueContainer()
    //
    //        if let value = try? container.decode(ConfigurationGroup.self) {
    //            self = .group(value)
    //            return
    //        }
    //        if let value = try? container.decode((any Configurable).self) {
    //            self = .value(value)
    //            return
    //        }
    //        throw DecodingError.typeMismatch(
    //            ConfigurationItem.self,
    //            DecodingError.Context(
    //                codingPath: decoder.codingPath,
    //                debugDescription: "Wrong type for ConfigurationItem",
    //            ),
    //        )
    //    }
    //
    //    package func encode(to encoder: any Encoder) throws {
    //        return
    //    }
    //}
}

