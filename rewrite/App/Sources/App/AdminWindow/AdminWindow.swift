import Combine
import ComposableArchitecture
import Foundation
import SwiftUI

class AdminWindow: NSObject {
  typealias Feature = AdminWindowFeature
  let store: Store<AppReducer.State, Feature.Action>
  var cancellables = Set<AnyCancellable>()
  var window: NSWindow?

  @Dependency(\.mainQueue) var mainQueue
  @ObservedObject var viewStore: ViewStore<Feature.State.View, Feature.Action>

  init(store: Store<AppReducer.State, Feature.Action>) {
    self.store = store
    viewStore = ViewStore(store, observe: Feature.State.View.init)
    super.init()

    viewStore.publisher.windowOpen
      .receive(on: mainQueue)
      .sink { open in
        if open {
          self.openWindow()
        } else {
          self.window?.close()
          self.window = nil
        }
      }
      .store(in: &cancellables)
  }
}

extension AdminWindow: NSWindowDelegate {
  func openWindow() {
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    window?.minSize = NSSize(width: 800, height: 500)

    window?.center()
    window?.title = "Administrate  |  Gertrude"
    window?.makeKeyAndOrderFront(nil)
    window?.isReleasedWhenClosed = false
    window?.delegate = self
    window?.tabbingMode = .disallowed
    window?.alphaValue = 0.0
    window?.titlebarAppearsTransparent = true
    // window?.level = .popUpMenu // keep on top of EVERY window

    let wvc = WebViewController<Feature.State.View, Feature.Action.View>()

    NSApp.activate(ignoringOtherApps: true)

    wvc.send = { [weak self] action in
      self?.viewStore.send(.webview(action))
    }

    viewStore.objectWillChange.sink { [mainQueue] _ in
      // tiny delay is because this gets run on WILL change, not DID change
      mainQueue.schedule(after: .microseconds(1)) { [weak self] in
        guard let self = self, wvc.isReady.value else { return }
        wvc.updateState(self.viewStore.state)
      }
    }.store(in: &cancellables)

    wvc.isReady
      .receive(on: mainQueue)
      .removeDuplicates()
      .prefix(2)
      .sink { [weak self] isReady in
        guard let self = self, isReady else { return }
        wvc.updateState(self.viewStore.state)
        // give time for appview to re-render
        self.mainQueue.schedule(after: .milliseconds(10)) { [weak self] in
          self?.window?.alphaValue = 1.0
        }
      }
      .store(in: &cancellables)

    wvc.loadWebView(screen: "Administrate")
    window?.contentView = wvc.view
  }

  func windowWillClose(_: Notification) {
    viewStore.send(.closeWindow)
    window = nil
  }
}
