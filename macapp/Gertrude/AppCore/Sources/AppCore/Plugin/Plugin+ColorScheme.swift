import SwiftUI

final class ColorSchemePlugin: Plugin {
  var observation: NSKeyValueObservation?

  init(store: AppStore) {
    store.send(.setColorScheme(appColorScheme()))
    observation = NSApp.observe(\.effectiveAppearance) { _, _ in
      store.send(.setColorScheme(appColorScheme()))
    }
  }

  func onTerminate() {
    observation?.invalidate()
  }
}

private func appColorScheme() -> ColorScheme {
  NSApp.effectiveAppearance.name == .darkAqua ? .dark : .light
}
