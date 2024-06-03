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
      self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
    } else {
      self.webView = NoTitleWebView(frame: .zero, configuration: webConfiguration)
    }
    self.webView.uiDelegate = self
    self.webView.setValue(false, forKey: "drawsBackground")

    let contentController = self.webView.configuration.userContentController
    contentController.add(self, name: "appView")

    #if DEBUG
      self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    #endif

    let colorScheme = self.supportsDarkMode ? self.app.colorScheme() : .light
    let filePathURL = URL(
      fileURLWithPath: "Contents/Resources/WebViews/\(screen)/index.\(colorScheme).html",
      relativeTo: Bundle.main.bundleURL
    )

    let fileDirectoryURL = filePathURL.deletingLastPathComponent()
    self.webView.loadFileURL(filePathURL, allowingReadAccessTo: fileDirectoryURL)
    view = self.webView
  }

  nonisolated func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard let message = message.body as? String else {
      #if DEBUG
        print("ERR: message.body from webview not string: \(message.body)")
      #endif
      return
    }

    if message == "__APPVIEW_READY__" {
      Task { [weak self] in
        await self?.ready()
      }
      return
    }

    do {
      let action = try JSON.decode(message, as: Action.self)
      Task { [weak self] in
        await self?.send(action: action)
      }
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

class NoTitleWebView: WKWebView {
  override var mouseDownCanMoveWindow: Bool { true }
}

typealias WebViewControllerOf<F: Feature> = WebViewController<
  F.Reducer.State,
  F.Reducer.Action
> where F.Reducer.State: Encodable, F.Reducer.Action: Decodable
