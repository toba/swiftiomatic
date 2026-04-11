import SwiftUI

struct AboutTab: View {
  private var version: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  }

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "swift")
        .font(.system(size: 64))
        .foregroundStyle(.orange)

      Text("Swiftiomatic")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Version \(version)")
        .foregroundStyle(.secondary)

      Divider()
        .frame(width: 200)

      VStack(alignment: .leading, spacing: 12) {
        Text("Activating the Extension")
          .font(.headline)
        Text("1. Open System Settings > Privacy & Security > Extensions")
        Text("2. Click Xcode Source Editor Extensions")
        Text("3. Enable Swiftiomatic")
        Text("4. Restart Xcode")
      }
      .frame(maxWidth: 400, alignment: .leading)

      Spacer()
    }
    .padding()
    .navigationTitle("About")
  }
}
