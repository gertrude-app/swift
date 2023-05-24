import Combine
import ComposableArchitecture
import Models
import WebKit
import XCore

class WebViewController<State, Action>:
  NSViewController, WKUIDelegate, WKScriptMessageHandler
  where Action: Sendable, Action: Decodable, State: Encodable {

  var webView: WKWebView!
  var isReady: CurrentValueSubject<Bool, Never> = .init(false)
  var send: (Action) -> Void = { _ in }

  @Dependency(\.app) var app

  func updateState(_ state: State) {
    if let json = try? JSON.encode(state, [.isoDates]) {
      webView.evaluateJavaScript("window.updateAppState(\(json))")
    }
  }

  func updateColorScheme(_ colorScheme: AppClient.ColorScheme) {
    webView.evaluateJavaScript("window.updateColorScheme('\(colorScheme.rawValue)')")
  }

  func loadWebView(screen: String) {
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
      fileURLWithPath: "Contents/Resources/WebViews/\(screen)/index.html",
      relativeTo: Bundle.main.bundleURL
    )

    let fileDirectoryURL = filePathURL.deletingLastPathComponent()
    webView.loadFileURL(filePathURL, allowingReadAccessTo: fileDirectoryURL)
    view = webView
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
      #if DEBUG
        let actionType = String(reflecting: Action.self)
        print("ERR: could not decode action from webview: \(message) as \(actionType)\n")
        print(error)
      #endif
    }
  }

  // helper fn to keep compiler happy re: concurrency
  @MainActor func send(action: Action) {
    send(action)
  }

  @MainActor func ready() {
    isReady.value = true
  }
}

typealias WebViewControllerOf<F: Feature> = WebViewController<
  F.Reducer.State,
  F.Reducer.Action
> where F.Reducer.State: Encodable, F.Reducer.Action: Decodable
