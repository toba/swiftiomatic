/// Extracts emoji markers from source text, mapping each to its UTF-8 offset.
///
/// Adapted from Apple's swift-format test support. Markers pinpoint expected
/// finding locations in test source strings:
///
///     let marked = MarkedText("let x = 1️⃣foo!")
///     // marked.markers == ["1️⃣": 8]
///     // marked.textWithoutMarkers == "let x = foo!"
struct MarkedText {
  /// Marker name → UTF-8 byte offset in the cleaned text.
  let markers: [String: Int]

  /// Source text with all marker emojis removed.
  let textWithoutMarkers: String

  init(_ markedText: String) {
    var text = ""
    var markers = [String: Int]()
    var lastIndex = markedText.startIndex

    for marker in Self.findMarkers(in: markedText) {
      text += markedText[lastIndex..<marker.range.lowerBound]
      lastIndex = marker.range.upperBound
      assert(markers[marker.name] == nil, "Marker '\(marker.name)' used more than once")
      markers[marker.name] = text.utf8.count
    }
    text += markedText[lastIndex..<markedText.endIndex]

    self.markers = markers
    self.textWithoutMarkers = text
  }
}

// MARK: - Marker Scanning

extension MarkedText {
  fileprivate struct Marker {
    let name: String
    let range: Range<String.Index>
  }

  fileprivate static func findMarkers(in text: String) -> [Marker] {
    var markers = [Marker]()
    var searchFrom = text.startIndex
    while let marker = nextMarker(in: text, from: searchFrom) {
      markers.append(marker)
      searchFrom = marker.range.upperBound
    }
    return markers
  }

  fileprivate static func nextMarker(in text: String, from index: String.Index) -> Marker? {
    guard let start = text[index...].firstIndex(where: \.isMarkerEmoji) else {
      return nil
    }
    let end = text.index(after: start)
    return Marker(name: String(text[start..<end]), range: start..<end)
  }
}

extension Character {
  fileprivate var isMarkerEmoji: Bool {
    switch self {
    case "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟":
      true
    default:
      false
    }
  }
}
