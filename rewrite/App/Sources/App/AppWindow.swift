import Combine
import ComposableArchitecture
import SwiftUI

protocol AppWindow: AnyObject {
  associatedtype State: Equatable, Encodable
  associatedtype Action: Sendable
  associatedtype WebViewAction: Decodable, Sendable

  var windowDelegate: AppWindowDelegate { get set }
  var viewStore: ViewStore<State, Action> { get set }
  var cancellables: Set<AnyCancellable> { get set }
  var window: NSWindow? { get set }
  var mainQueue: AnySchedulerOf<DispatchQueue> { get }
  var openPublisher: StorePublisher<Bool> { get }
  var initialSize: NSRect { get }
  var minSize: NSSize { get }
  var windowLevel: NSWindow.Level { get }
  var title: String { get }
  var screen: String { get }
  var closeWindowAction: Action { get }

  func embed(_ webviewAction: WebViewAction) -> Action
}

extension AppWindow {
  var windowLevel: NSWindow.Level { .normal }
  var initialSize: NSRect { NSRect(x: 0, y: 0, width: 900, height: 600) }
  var minSize: NSSize { NSSize(width: 800, height: 500) }

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
    window?.minSize = NSSize(width: 800, height: 500)

    window?.center()
    window?.title = "\(title)  |  Gertrude"
    window?.makeKeyAndOrderFront(nil)
    window?.delegate = windowDelegate
    window?.tabbingMode = .disallowed
    window?.alphaValue = 0.0
    window?.titlebarAppearsTransparent = true
    window?.isReleasedWhenClosed = false
    window?.level = windowLevel

    let wvc = WebViewController<State, WebViewAction>()

    NSApp.activate(ignoringOtherApps: true)

    wvc.send = { [weak self] action in
      guard let self = self else { return }
      self.viewStore.send(self.embed(action))
    }

    viewStore.publisher
      .receive(on: mainQueue)
      .sink { [weak self] _ in
        guard let self = self, wvc.isReady.value else { return }
        wvc.updateState(self.viewStore.state)
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
