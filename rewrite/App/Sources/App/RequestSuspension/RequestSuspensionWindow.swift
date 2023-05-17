import Combine
import ComposableArchitecture
import Foundation
import SwiftUI

class RequestSuspensionWindow: AppWindow {
  typealias Feature = RequestSuspensionFeature
  typealias Action = Feature.Action
  typealias State = Feature.State
  typealias WebViewAction = Feature.Action.View

  var title = "Request Suspension"
  var screen = "RequestSuspension"
  var openPublisher: StorePublisher<Bool>
  var cancellables = Set<AnyCancellable>()
  var windowDelegate = AppWindowDelegate()
  var viewStore: ViewStore<State, Action>
  var window: NSWindow?
  var initialSize = NSRect(x: 0, y: 0, width: 600, height: 380)
  var minSize = NSSize(width: 600, height: 380)
  var closeWindowAction = Action.closeWindow

  // above almost everything, but below filter installation system prompt
  var windowLevel = NSWindow.Level.modalPanel

  @Dependency(\.mainQueue) var mainQueue

  @MainActor init(store: StoreOf<Feature.Reducer>) {
    viewStore = ViewStore(store, observe: { $0 })
    openPublisher = viewStore.publisher.windowOpen
    bind()
  }

  func embed(_ webviewAction: WebViewAction) -> Action {
    .webview(webviewAction)
  }
}
