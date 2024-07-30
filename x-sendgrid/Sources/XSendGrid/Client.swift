import Foundation
import XHttp

#if canImport(FoundationNetworking)
  @preconcurrency import FoundationNetworking
#endif

public extension SendGrid {
  struct Client: Sendable {
    public var send: @Sendable (Email) async throws -> Void

    public init(send: @Sendable @escaping (Email) async throws -> Void) {
      self.send = send
    }

    public func fireAndForget(_ email: Email) {
      Task {
        do {
          try await self.send(email)
        } catch {}
      }
    }
  }
}

// extensions

public extension SendGrid.Client {
  enum Error: Swift.Error, Sendable {
    case unexpectedResponse(statusCode: Int, response: URLResponse)
  }

  static func live(apiKey: String) -> Self {
    SendGrid.Client(send: { email in
      let (_, response) = try await HTTP.postJson(
        email,
        to: "https://api.sendgrid.com/v3/mail/send",
        auth: .bearer(apiKey),
        keyEncodingStrategy: .convertToSnakeCase
      )
      if response.statusCode != 202 {
        throw Error.unexpectedResponse(statusCode: response.statusCode, response: response)
      }
    })
  }
}

public extension SendGrid.Client {
  static let mock: Self = .init(send: { _ in })
}
