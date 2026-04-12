import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

struct ScopeBadge: View {
  let scope: Scope

  private var color: Color {
    switch scope {
    case .lint: .orange
    case .format: .blue
    case .suggest: .purple
    }
  }

  private var symbolName: String {
    switch scope {
    case .lint: "exclamationmark.triangle"
    case .format: "guidepoint.vertical.numbers"
    case .suggest: "character.textbox.badge.sparkles"
    }
  }

  var body: some View {
    Image(systemName: symbolName)
      .foregroundStyle(color)
  }
}
