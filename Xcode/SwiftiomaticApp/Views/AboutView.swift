import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("Swiftiomatic").font(.title)

            VStack(spacing: 6) {
                Text("Version \(version)")
                Text("© 2025–2026 Toba LLC")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Divider().frame(width: 200)

            VStack(alignment: .leading) {
                Text("A remix of")
                Text("SwiftLint")
                Text("SwiftFormat")
                Text("swift-format")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Activating the Xcode Extension").font(.headline)
                VStack(alignment: .leading) {
                    Text("1. Open System Settings > Privacy & Security > Extensions")
                    Text("2. Click Xcode Source Editor Extensions")
                    Text("3. Enable Swiftiomatic")
                    Text("4. Restart Xcode")
                }.padding(6)
            }
            .font(.callout)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 325)
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .containerBackground(.regularMaterial, for: .window)
        .windowMinimizeBehavior(.disabled)
    }
}

#Preview {
    AboutView()
}

