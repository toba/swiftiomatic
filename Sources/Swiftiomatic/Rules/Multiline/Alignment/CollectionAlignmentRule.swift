import SwiftSyntax

struct CollectionAlignmentRule {
  var options = CollectionAlignmentOptions()

  static let configuration = CollectionAlignmentConfiguration()
}

extension CollectionAlignmentRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension CollectionAlignmentRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ArrayExprSyntax) {
      let locations = node.elements.map { element in
        locationConverter.location(for: element.positionAfterSkippingLeadingTrivia)
      }
      violations.append(contentsOf: validate(keyLocations: locations))
    }

    override func visitPost(_ node: DictionaryElementListSyntax) {
      let locations = node.map { element in
        let position =
          configuration.alignColons
          ? element.colon.positionAfterSkippingLeadingTrivia
          : element.key.positionAfterSkippingLeadingTrivia
        let location = locationConverter.location(for: position)

        let graphemeColumn: Int
        let graphemeClusters = String(
          locationConverter.sourceLines[location.line - 1].utf8
            .prefix(location.column - 1),
        )
        if let graphemeClusters {
          graphemeColumn = graphemeClusters.count + 1
        } else {
          graphemeColumn = location.column
        }

        return SourceLocation(
          line: location.line,
          column: graphemeColumn,
          offset: location.offset,
          file: location.file,
        )
      }
      violations.append(contentsOf: validate(keyLocations: locations))
    }

    private func validate(keyLocations: [SourceLocation]) -> [AbsolutePosition] {
      guard keyLocations.count >= 2 else {
        return []
      }

      let firstKeyLocation = keyLocations[0]
      let remainingKeyLocations = keyLocations[1...]

      return zip(remainingKeyLocations.indices, remainingKeyLocations)
        .compactMap { index, location -> AbsolutePosition? in
          let previousLocation = keyLocations[index - 1]
          let previousLine = previousLocation.line
          let locationLine = location.line
          let firstKeyColumn = firstKeyLocation.column
          let locationColumn = location.column
          guard previousLine < locationLine, firstKeyColumn != locationColumn else {
            return nil
          }

          return locationConverter.position(ofLine: locationLine, column: locationColumn)
        }
    }
  }
}

