import ClientInterfaces
import Combine
import ComposableArchitecture
import WebKit
import XCore

class WebViewController<State, Action>:
  NSViewController, WKUIDelegate, WKScriptMessageHandler
  where Action: Sendable, Action: Decodable, State: Encodable {

  var webView: WKWebView!
  var isReady: CurrentValueSubject<Bool, Never> = .init(false)
  var send: (Action) -> Void = { _ in }
  var withTitleBar = false
  var supportsDarkMode = true

  @Dependency(\.app) var app

  func updateState(_ state: State) {
    if let json = try? JSON.encode(state, [.isoDates]) {
      self.webView.evaluateJavaScript("window.updateAppState(\(json))")
    }
  }

  func updateColorScheme(_ colorScheme: AppClient.ColorScheme) {
    if self.supportsDarkMode {
      self.webView.evaluateJavaScript("window.updateColorScheme('\(colorScheme.rawValue)')")
    }
  }

  func loadWebView(screen: String) {
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
    if #available(macOS 12.3, *) {
      // allow embedded youtube videos to go fullscreen
      webConfiguration.preferences.isElementFullscreenEnabled = true
    }

    if self.withTitleBar {
      self.webView = GertrudeWebview(frame: .zero, configuration: webConfiguration)
    } else {
      self.webView = NoTitleWebView(frame: .zero, configuration: webConfiguration)
    }
    self.webView.uiDelegate = self
    self.webView.setValue(false, forKey: "drawsBackground")

    let contentController = self.webView.configuration.userContentController
    contentController.add(self, name: "appView")

    #if DEBUG
      self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    #else
      if allowWebviewDebugging() {
        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
      }
    #endif

    let colorScheme = self.supportsDarkMode ? self.app.colorScheme() : .light
    let filePathURL = URL(
      fileURLWithPath: "Contents/Resources/WebViews/\(screen)/index.\(colorScheme).html",
      relativeTo: Bundle.main.bundleURL,
    )

    let fileDirectoryURL = filePathURL.deletingLastPathComponent()
    self.webView.loadFileURL(filePathURL, allowingReadAccessTo: fileDirectoryURL)
    view = self.webView
  }

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage,
  ) {
    guard let message = message.body as? String else {
      #if DEBUG
        print("ERR: message.body from webview not string: \(message.body)")
      #endif
      return
    }

    if message == "__APPVIEW_READY__" {
      self.ready()
      return
    }

    do {
      let action = try JSON.decode(message, as: Action.self)
      self.send(action: action)
    } catch {
      let actionType = String(reflecting: Action.self)
      let errMsg = "ERR: could not decode action from webview: \(message) as \(actionType)\n"
      #if DEBUG
        print(errMsg)
        print(error)
      #else
        unexpectedError(id: "0645e891", detail: errMsg)
      #endif
    }
  }

  // helper fn to keep compiler happy re: concurrency
  @MainActor func send(action: Action) {
    self.send(action)
  }

  @MainActor func ready() {
    self.isReady.value = true
  }
}

class GertrudeWebview: WKWebView {
  #if !DEBUG
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
      if let reloadMenuItem = menu.item(withTitle: "Reload"), !allowWebviewDebugging() {
        menu.removeItem(reloadMenuItem)
      }
    }
  #endif
}

class NoTitleWebView: GertrudeWebview {
  override var mouseDownCanMoveWindow: Bool { true }
}

private func allowWebviewDebugging() -> Bool {
  #if DEBUG
    return true
  #else
    if UserDefaults.standard.bool(forKey: "allowWebviewDebugging") {
      return true
    } else if let envVar = ProcessInfo.processInfo.environment["ALLOW_WEBVIEW_DEBUGGING"] {
      return toHash(envVar) == "a430287a9c7400e48d720da20b7e71b56b8f641347319123c7d3ed4815197830"
    } else {
      return false
    }
  #endif
}

#if canImport(CryptoKit)
  import CryptoKit

  func toHash(_ input: String) -> String {
    if let inputData = input.data(using: .utf8) {
      let hash = SHA256.hash(data: inputData)
      return hash.compactMap { String(format: "%02x", $0) }.joined()
    } else {
      return UUID().uuidString
    }
  }
#else
  func toHash(_ input: String) -> String {
    UUID().uuidString
  }
#endif

typealias WebViewControllerOf<F: Feature> = WebViewController<
  F.Reducer.State,
  F.Reducer.Action,
> where F.Reducer.State: Encodable, F.Reducer.Action: Decodable
