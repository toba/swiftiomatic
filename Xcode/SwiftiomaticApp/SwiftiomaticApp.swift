import SwiftUI

@main
struct SwiftiomaticApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
        .defaultSize(width: 900, height: 600)
    }
}
