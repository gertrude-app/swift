import ComposableArchitecture
import WebKit
import XCore

class WebViewController<State, Action>:
  NSViewController, WKUIDelegate, WKScriptMessageHandler
  where Action: Sendable, Action: Decodable, State: Encodable {

  var webView: WKWebView!
  var send: (Action) -> Void = { _ in }

  func updateState(_ state: State) {
    if let json = try? JSON.encode(state, [.isoDates]) {
      webView.evaluateJavaScript("window.updateAppState(\(json))")
    }
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
    guard let json = message.body as? String else {
      return
    }

    guard let action = try? JSON.decode(json, as: Action.self) else {
      return
    }

    Task { [weak self] in
      await self?.send(action: action)
    }
  }

  // helper fn to keep compiler happy re: concurrency
  @MainActor func send(action: Action) {
    send(action)
  }
}

typealias WebViewControllerOf<F: Feature> = WebViewController<
  F.Reducer.State,
  F.Reducer.Action
> where F.Reducer.State: Encodable, F.Reducer.Action: Decodable
