import WebKit
import XCore

class WebViewController<State: Encodable, Action: Decodable>:
  NSViewController, WKUIDelegate, WKScriptMessageHandler {
  var webView: WKWebView!
  var send: (Action) -> Void = { _ in }

  func updateState(_ state: State) {
    if let json = try? JSON.encode(state) {
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

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard let json = message.body as? String else {
      return
    }

    guard let action = try? JSON.decode(json, as: Action.self) else {
      return
    }

    send(action)
  }
}
