import AppKit
import ClientInterfaces
import Combine
import ComposableArchitecture

protocol AppWindow: AnyObject {
  associatedtype State: Equatable, Encodable
  associatedtype Action: Sendable
  associatedtype WebViewAction: Decodable, Sendable

  var windowDelegate: AppWindowDelegate { get set }
  var viewStore: ViewStore<State, Action> { get set }
  var cancellables: Set<AnyCancellable> { get set }
  var window: NSWindow? { get set }
  var mainQueue: AnySchedulerOf<DispatchQueue> { get }
  var appClient: AppClient { get }
  var openPublisher: StorePublisher<Bool> { get }
  var initialSize: NSRect { get }
  var minSize: NSSize { get }
  var windowLevel: NSWindow.Level { get }
  var title: String { get }
  var screen: String { get }
  var showTitleBar: Bool { get }
  var closeWindowAction: Action { get }

  func embed(_ webviewAction: WebViewAction) -> Action
}

extension AppWindow {
  var windowLevel: NSWindow.Level { .normal }
  var initialSize: NSRect { NSRect(x: 0, y: 0, width: 900, height: 600) }
  var minSize: NSSize { NSSize(width: 800, height: 500) }
  var showTitleBar: Bool { true }

  @MainActor func bind() {
    windowDelegate.events
      .receive(on: mainQueue)
      .sink { [weak self] event in
        guard let self = self else { return }
        switch event {
        case .willClose:
          self.window = nil
          self.viewStore.send(self.closeWindowAction)
        }
      }.store(in: &cancellables)

    openPublisher
      .receive(on: mainQueue)
      .sink { [weak self] open in
        if open {
          self?.openWindow()
        } else {
          self?.window?.close()
          self?.window = nil
        }
      }
      .store(in: &cancellables)
  }

  @MainActor func openWindow() {
    window = NSWindow(
      contentRect: initialSize,
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    window?.minSize = minSize
    window?.center()
    window?.title = "\(title)  |  Gertrude"
    window?.delegate = windowDelegate
    window?.tabbingMode = .disallowed
    window?.titlebarAppearsTransparent = true

    if !showTitleBar {
      window?.titleVisibility = .hidden
      window?.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
      window?.isMovableByWindowBackground = true
    }

    window?.isReleasedWhenClosed = false
    window?.level = windowLevel

    let wvc = WebViewController<State, WebViewAction>()
    wvc.withTitleBar = showTitleBar

    wvc.send = { [weak self] action in
      guard let self = self else { return }
      self.viewStore.send(self.embed(action))
    }

    // send state updates through to the webview
    viewStore.publisher
      .receive(on: mainQueue)
      .sink { [weak self] _ in
        guard let self = self, wvc.isReady.value else { return }
        wvc.updateState(self.viewStore.state)
      }.store(in: &cancellables)

    appClient.colorSchemeChanges()
      .receive(on: mainQueue)
      .sink { colorScheme in
        guard wvc.isReady.value else { return }
        wvc.updateColorScheme(colorScheme)
      }
      .store(in: &cancellables)

    // send initial state & show window when webview becomes ready
    wvc.isReady
      .receive(on: mainQueue)
      .removeDuplicates()
      .prefix(2)
      .sink { [weak self] isReady in
        guard let self = self, isReady else { return }
        wvc.updateState(self.viewStore.state)
        wvc.updateColorScheme(self.appClient.colorScheme())
        // give a brief moment for appview to re-render
        self.mainQueue.schedule(after: .milliseconds(75)) { [weak self] in
          // this exact order is required so that windows are not greyed out, hidden
          // and so that the webview focus/hover states etc. are immediately active
          // see: https://stackoverflow.com/questions/11160180
          // see: https://github.com/tauri-apps/wry/issues/175#issuecomment-824187262
          NSApp.activate(ignoringOtherApps: true)
          self?.window?.makeKeyAndOrderFront(nil)
        }
      }
      .store(in: &cancellables)

    wvc.loadWebView(screen: screen)
    window?.contentView = wvc.view
  }
}

extension AppWindow where Action == WebViewAction {
  func embed(_ webviewAction: WebViewAction) -> Action {
    webviewAction
  }
}

class AppWindowDelegate: NSObject, NSWindowDelegate {
  enum Event { case willClose }

  let events = PassthroughSubject<Event, Never>()

  func windowWillClose(_ notification: Notification) {
    events.send(.willClose)
  }
}
