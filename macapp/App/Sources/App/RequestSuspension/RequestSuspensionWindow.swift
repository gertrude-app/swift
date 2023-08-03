import Combine
import ComposableArchitecture
import Foundation
import SwiftUI

class RequestSuspensionWindow: AppWindow {
  typealias Feature = RequestSuspensionFeature
  typealias Action = Feature.Action
  typealias State = Feature.State.View
  typealias WebViewAction = Feature.Action.View

  var title = "Request Suspension"
  var screen = "RequestSuspension"
  var openPublisher: StorePublisher<Bool>
  var cancellables = Set<AnyCancellable>()
  var windowDelegate = AppWindowDelegate()
  var viewStore: ViewStore<State, Action>
  var window: NSWindow?
  var closeWindowAction = Action.closeWindow
  var initialSize = NSRect(x: 0, y: 0, width: 680, height: 360)
  var minSize = NSSize(width: 600, height: 360)

  // above almost everything, but below filter installation system prompt
  var windowLevel = NSWindow.Level.modalPanel

  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.app) var appClient

  @MainActor init(store: Store<AppReducer.State, Feature.Action>) {
    viewStore = ViewStore(store, observe: Feature.State.View.init)
    openPublisher = viewStore.publisher.windowOpen
    bind()
  }

  func embed(_ webviewAction: WebViewAction) -> Action {
    .webview(webviewAction)
  }
}
