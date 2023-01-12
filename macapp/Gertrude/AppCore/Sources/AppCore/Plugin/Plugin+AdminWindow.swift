import Foundation
import SwiftUI

class AdminWindowPlugin: NSObject, WindowPlugin {
  var windowOpen = false
  var store: AppStore
  var window: NSWindow?
  var title = "Administrate  |  Gertrude"

  var contentView: NSView {
    NSHostingView(rootView: AdminWindow().environmentObject(store))
  }

  init(store: AppStore) {
    self.store = store
  }

  func respond(to event: AppEvent) {
    switch event {
    case .adminWindowOpened:
      openWindow()
    default:
      break
    }
  }

  func windowWillClose(_ notification: Notification) {
    windowOpen = false
  }
}
