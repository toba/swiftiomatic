import Foundation
import SwiftiomaticKit

/// Load configuration from the App Group UserDefaults, falling back to defaults.
func loadConfiguration() -> Configuration {
  guard let defaults = SharedDefaults.suite,
    let yaml = defaults.string(forKey: SharedDefaults.configYAMLKey)
  else {
    return .default
  }
  return Configuration.fromYAMLString(yaml)
}
