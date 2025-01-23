import AppKit
import Combine
import ComposableArchitecture
import Foundation

class AdminWindow: AppWindow {
  typealias Feature = AdminWindowFeature
  typealias Action = Feature.Action
  typealias State = Feature.State.View
  typealias WebViewAction = Feature.Action.View

  var title = "Administrate"
  var screen = "Administrate"
  var openPublisher: StorePublisher<Bool>
  var cancellables = Set<AnyCancellable>()
  var windowDelegate = AppWindowDelegate()
  var viewStore: ViewStore<State, Action>
  var window: NSWindow?
  var initialSize = NSRect(x: 0, y: 0, width: 900, height: 660)
  var minSize = NSSize(width: 800, height: 560)
  var closeWindowAction = Action.closeWindow

  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.app) var appClient

  @MainActor init(store: Store<AppReducer.State, Feature.Action>) {
    self.viewStore = ViewStore(store, observe: AdminWindowFeature.State.View.init)
    self.openPublisher = self.viewStore.publisher.windowOpen
    bind()
  }

  func embed(_ webviewAction: WebViewAction) -> Action {
    .webview(webviewAction)
  }
}
