import SwiftUI

struct ContentView: View {
  var body: some View {
    TabView {
      Tab("Rules", systemImage: "checklist") {
        RulesTab()
      }
      Tab("Options", systemImage: "gearshape") {
        OptionsTab()
      }
      Tab("About", systemImage: "info.circle") {
        AboutTab()
      }
    }
  }
}
