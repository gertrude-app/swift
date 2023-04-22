import Combine
import ComposableArchitecture
import Foundation
import SwiftUI

class BlockedRequestsWindow: NSObject {
  typealias Feature = BlockedRequestsFeature
  let store: StoreOf<Feature.Reducer>
  var cancellables = Set<AnyCancellable>()
  var window: NSWindow?

  @Dependency(\.mainQueue) var mainQueue
  @ObservedObject var viewStore: ViewStore<Feature.State.View, Feature.Action>

  init(store: StoreOf<Feature.Reducer>) {
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

extension BlockedRequestsWindow: NSWindowDelegate {
  func openWindow() {
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    window?.minSize = NSSize(width: 800, height: 500)

    window?.center()
    window?.title = "Blocked Requests  |  Gertrude"
    window?.makeKeyAndOrderFront(nil)
    window?.isReleasedWhenClosed = false
    window?.delegate = self
    window?.tabbingMode = .disallowed
    window?.alphaValue = 0.0
    window?.titlebarAppearsTransparent = true
    window?.level = .popUpMenu // keep on top of EVERY window

    let wvc = WebViewController<Feature.State.View, Feature.Action.View>()
    wvc.loadWebView(screen: "BlockedRequests")

    window?.contentView = wvc.view

    NSApp.activate(ignoringOtherApps: true)

    wvc.send = { [weak self] action in
      self?.viewStore.send(.webview(action))
    }

    viewStore.objectWillChange.sink { [mainQueue] _ in
      mainQueue.schedule(after: mainQueue.now.advanced(by: .microseconds(1))) { [weak self] in
        guard let self = self else { return }
        wvc.updateState(self.viewStore.state)
      }
    }.store(in: &cancellables)

    mainQueue.schedule(after: mainQueue.now.advanced(by: .milliseconds(500))) { [weak self] in
      guard let self = self else { return }
      wvc.updateState(self.viewStore.state)
      self.window?.alphaValue = 1.0
    }
  }

  func windowWillClose(_ notification: Notification) {
    viewStore.send(.closeWindow)
    window = nil
  }
}
