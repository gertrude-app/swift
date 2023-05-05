import Combine
import ComposableArchitecture
import SwiftUI

class BlockedRequestsWindow: AppWindow {
  typealias Feature = BlockedRequestsFeature
  typealias State = Feature.State.View
  typealias Action = Feature.Action
  typealias WebViewAction = Feature.Action.View

  var title = "Blocked Requests"
  var screen = "BlockedRequests"
  var openPublisher: StorePublisher<Bool>
  var cancellables = Set<AnyCancellable>()
  var windowDelegate = AppWindowDelegate()
  var viewStore: ViewStore<State, Action>
  var window: NSWindow?
  var initialSize = NSRect(x: 0, y: 0, width: 900, height: 600)
  var minSize = NSSize(width: 800, height: 500)
  var closeWindowAction = Action.closeWindow

  @Dependency(\.mainQueue) var mainQueue

  @MainActor init(store: StoreOf<Feature.Reducer>) {
    viewStore = ViewStore(store, observe: BlockedRequestsFeature.State.View.init)
    openPublisher = viewStore.publisher.windowOpen
    bind()
  }

  func embed(_ webviewAction: WebViewAction) -> Action {
    .webview(webviewAction)
  }
}