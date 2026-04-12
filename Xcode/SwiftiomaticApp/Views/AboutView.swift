import SwiftUI

struct AboutView: View {
  private var version: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  }

  private var build: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
  }

  var body: some View {
    VStack(spacing: 14) {
      Image(systemName: "swift")
        .font(.system(size: 64))
        .foregroundStyle(.orange)

      Text("Swiftiomatic")
        .font(.title)

      VStack(spacing: 6) {
        Text("Version \(version) (\(build))")
        Text("© 2025 Toba Technology")
      }
      .font(.callout)
      .foregroundStyle(.secondary)

      Divider()
        .frame(width: 200)

      VStack(alignment: .leading, spacing: 8) {
        Text("Activating the Extension")
          .font(.headline)
        Text("1. Open System Settings > Privacy & Security > Extensions")
        Text("2. Click Xcode Source Editor Extensions")
        Text("3. Enable Swiftiomatic")
        Text("4. Restart Xcode")
      }
      .font(.callout)
    }
    .padding()
    .frame(minWidth: 400, minHeight: 300)
    .toolbar(removing: .title)
    .toolbarBackground(.hidden, for: .windowToolbar)
    .containerBackground(.regularMaterial, for: .window)
    .windowMinimizeBehavior(.disabled)
  }
}
