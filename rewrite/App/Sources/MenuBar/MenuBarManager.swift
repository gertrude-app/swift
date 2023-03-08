import Cocoa
import Combine
import ComposableArchitecture
import SwiftUI
import WebKit

class ViewController: NSViewController, WKUIDelegate {
  var webView: WKWebView!
  var send: (MenuBar.Action) -> Void = { _ in }

  func updateState(_ state: MenuBar.State.Screen) {
    let json: String
    if case .connected(let user) = state {
      json = """
      {
        "state": "connected",
        "recordingKeystrokes": \(user.recordingKeystrokes),
        "recordingScreenshots": \(user.recordingScreen),
        "filterState": { "state": "on" }
      }
      """
    } else {
      json = #"{ "state": "notConnected" }"#
    }

    webView.evaluateJavaScript("window.updateAppState(\(json))")
  }

  func loadWebView() {
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
    webView = WKWebView(frame: .zero, configuration: webConfiguration)
    webView.uiDelegate = self
    webView.setValue(false, forKey: "drawsBackground")

    let contentController = webView.configuration.userContentController
    contentController.add(self, name: "appView")

    #if DEBUG
      webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    #endif

    let filePathURL = URL(
      fileURLWithPath: "Contents/Resources/WebViews/MenuBar/index.html",
      relativeTo: Bundle.main.bundleURL
    )

    let fileDirectoryURL = filePathURL.deletingLastPathComponent()
    webView.loadFileURL(filePathURL, allowingReadAccessTo: fileDirectoryURL)
    view = webView
  }
}

extension ViewController: WKScriptMessageHandler {
  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard let msgString = message.body as? String else {
      return
    }

    guard let action = MenuBar.Action(rawValue: msgString) else {
      return
    }
    send(action)
  }
}

@MainActor public class MenuBarManager {
  let store: StoreOf<MenuBar>
  var statusItem: NSStatusItem
  var popover: NSPopover
  var cancellables = Set<AnyCancellable>()
  var vc: ViewController!

  @ObservedObject var viewStore: ViewStore<MenuBar.State.Screen, MenuBar.Action>

  public init(store: StoreOf<MenuBar>) {
    self.store = store
    viewStore = ViewStore(store, observe: \.screen)

    popover = NSPopover()
    popover.animates = false
    popover.behavior = .applicationDefined

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(named: "MenuBarIcon")
    statusItem.button?.image?.isTemplate = true // auto-coloring/inverting of image
    statusItem.button?.action = #selector(iconClicked(_:))
    statusItem.button?.target = self

    // let view = MenuBarView(store: self.store)
    // popover.contentViewController = NSHostingController(rootView: view)
    let vc = ViewController()
    vc.send = { [weak self] action in self?.viewStore.send(action) }
    vc.loadWebView()
    self.vc = vc
    popover.contentViewController = vc
    sizePopover()

    // resize popover when store gets a change
    viewStore.objectWillChange.sink { _ in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.sizePopover()
        self.vc.updateState(self.viewStore.state)
      }
    }.store(in: &cancellables)
  }

  func sizePopover() {
    let (width, height) = viewStore.state.viewDimensions
    popover.contentSize = NSSize(width: width, height: height)
  }

  @objc func iconClicked(_ sender: Any?) {
    viewStore.send(.menuBarIconClicked)
    if popover.isShown {
      popover.performClose(sender)
      return
    }
    guard let button = statusItem.button else { return }
    sizePopover()
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY)
    popover.contentViewController?.view.window?.becomeKey()
  }
}
