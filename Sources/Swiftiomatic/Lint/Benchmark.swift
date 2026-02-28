import Foundation

extension Duration {
    var timeInterval: Double {
        let (seconds, attoseconds) = components
        return Double(seconds) + Double(attoseconds) * 1e-18
    }
}

struct BenchmarkEntry {
    let id: String
    let time: Double
}

struct Benchmark {
    private let name: String
    private var entries = [BenchmarkEntry]()

    init(name: String) {
        self.name = name
    }

    mutating func record(id: String, time: Double) {
        entries.append(BenchmarkEntry(id: id, time: time))
    }

    mutating func record(file: SwiftSource, from start: ContinuousClock.Instant) {
        record(id: file.path ?? "<nopath>", time: (ContinuousClock.now - start).timeInterval)
    }

    func save() {
        // Decomposed to improve compile times
        let entriesDict: [String: Double] = entries.reduce(into: [String: Double]()) {
            accu, idAndTime in
            accu[idAndTime.id] = (accu[idAndTime.id] ?? 0) + idAndTime.time
        }
        let entriesKeyValues: [(String, Double)] = entriesDict.sorted { $0.1 < $1.1 }
        let lines: [String] = entriesKeyValues.map { id, time -> String in
            // sm:disable:next legacy_objc_type
            "\(numberFormatter.string(from: NSNumber(value: time))!): \(id)"
        }
        let string: String = lines.joined(separator: "\n") + "\n"
        let url = URL(fileURLWithPath: "benchmark_\(name)_\(timestamp).txt", isDirectory: false)
        try? string.data(using: .utf8)?.write(to: url, options: [.atomic])
    }
}

private let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 3
    return formatter
}()

private let timestamp: String = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
    return formatter.string(from: Date())
}()
