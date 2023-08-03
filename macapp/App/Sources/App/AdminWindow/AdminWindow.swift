import Combine
import ComposableArchitecture
import Foundation
import SwiftUI

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
  var initialSize = NSRect(x: 0, y: 0, width: 900, height: 600)
  var minSize = NSSize(width: 800, height: 500)
  var closeWindowAction = Action.closeWindow

  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.app) var appClient

  @MainActor init(store: Store<AppReducer.State, Feature.Action>) {
    viewStore = ViewStore(store, observe: AdminWindowFeature.State.View.init)
    openPublisher = viewStore.publisher.windowOpen
    bind()
  }

  func embed(_ webviewAction: WebViewAction) -> Action {
    .webview(webviewAction)
  }
}
