import AppKit
import Combine
import ComposableArchitecture

class OnboardingWindow: AppWindow {
  typealias Feature = OnboardingFeature
  typealias State = Feature.State.View
  typealias Action = Feature.Action
  typealias WebViewAction = Feature.Action.View

  var title = "Onboarding"
  var screen = "Onboarding"
  var openPublisher: StorePublisher<Bool>
  var cancellables = Set<AnyCancellable>()
  var windowDelegate = AppWindowDelegate()
  var viewStore: ViewStore<State, Action>
  var window: NSWindow?
  var closeWindowAction = Action.closeWindow
  var initialSize = NSRect(x: 0, y: 0, width: 900, height: 700)
  var minSize = NSSize(width: 800, height: 600)
  var showTitleBar = false
  var supportsDarkMode = false

  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.app) var appClient

  @MainActor init(store: Store<AppReducer.State, Feature.Action>) {
    self.viewStore = ViewStore(store, observe: OnboardingFeature.State.View.init)
    self.openPublisher = self.viewStore.publisher.windowOpen
    bind()
  }

  func embed(_ webviewAction: WebViewAction) -> Action {
    .webview(webviewAction)
  }
}
