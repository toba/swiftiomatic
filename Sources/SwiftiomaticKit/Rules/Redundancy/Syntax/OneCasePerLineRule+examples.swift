import SwiftiomaticSyntax

extension OneCasePerLineRule {
  static var nonTriggeringExamples: [Example] {
    [
      // Plain cases grouped — no payloads
      Example(
        """
        enum Direction {
            case north, south, east, west
        }
        """
      ),
      // Single case with associated value
      Example(
        """
        enum Token {
            case identifier(String)
        }
        """
      ),
      // Single case with raw value
      Example(
        """
        enum Coin: Int {
            case penny = 1
        }
        """
      ),
      // Each associated value case already on its own line
      Example(
        """
        enum Token {
            case identifier(String)
            case literal(Int)
            case comma, semicolon
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // Multiple associated value cases on one line
      Example(
        """
        enum Token {
            case ↓identifier(String), ↓literal(Int)
        }
        """
      ),
      // Mixed plain and associated value cases
      Example(
        """
        enum Token {
            case comma, ↓identifier(String), semicolon
        }
        """
      ),
      // Multiple raw value cases on one line
      Example(
        """
        enum Bracket: String {
            case ↓leftParen = "(", ↓rightParen = ")"
        }
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        enum Token {
            case ↓identifier(String), ↓literal(Int)
        }
        """
      ): Example(
        """
        enum Token {
            case identifier(String)
        case literal(Int)
        }
        """
      ),
      Example(
        """
        enum Token {
            case comma, ↓identifier(String), semicolon
        }
        """
      ): Example(
        """
        enum Token {
            case comma
        case identifier(String)
        case semicolon
        }
        """
      ),
      Example(
        """
        enum Bracket: String {
            case ↓leftParen = "(", ↓rightParen = ")"
        }
        """
      ): Example(
        """
        enum Bracket: String {
            case leftParen = "("
        case rightParen = ")"
        }
        """
      ),
    ]
  }
}
