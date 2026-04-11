import SwiftUI
import Swiftiomatic

struct ScopeBadge: View {
  let scope: Scope

  private var color: Color {
    switch scope {
    case .lint: .orange
    case .format: .blue
    case .suggest: .purple
    }
  }

  var body: some View {
    Text(scope.displayName)
      .font(.caption2)
      .fontWeight(.semibold)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(color.opacity(0.15), in: .capsule)
      .foregroundStyle(color)
  }
}
