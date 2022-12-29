import XHttp

public extension Slack {
  struct Client {
    public var send = send(_:token:)

    public init() {}

    public init(send: @escaping (Slack.Message, String) async -> String?) {
      self.send = send
    }
  }
}

private func send(_ slack: Slack.Message, token: String) async -> String? {
  var slack = slack

  if case .text(let text) = slack.content {
    let safeText = text.dropLast(max(0, text.count - MAX_SAFE_SLACK_MSG_LENGTH))
    slack.content = .text(String(safeText))
  }

  do {
    let response = try await HTTP.postJson(
      slack,
      to: "https://slack.com/api/chat.postMessage",
      decoding: SendResponse.self,
      auth: .bearer(token),
      keyEncodingStrategy: .convertToSnakeCase
    )
    if !response.ok {
      return response.error ?? "unknown error"
    }
    return nil
  } catch {
    return String(describing: error)
  }
}

private let MAX_SAFE_SLACK_MSG_LENGTH = 2900

private struct SendResponse: Decodable {
  let ok: Bool
  let error: String?
}

// extensions

public extension Slack.Client {
  static var live: Slack.Client = .init(send: send(_:token:))
  static var mock: Slack.Client = .init(send: { _, _ in nil })
}
