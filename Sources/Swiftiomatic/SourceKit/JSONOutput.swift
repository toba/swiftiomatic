import Foundation

private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
}()

func toJSON<T: Encodable>(_ value: T) -> String {
    do {
        let data = try jsonEncoder.encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    } catch {
        return ""
    }
}
