import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct Client {
  public var send: (Email) async throws -> Void

  public init(send: @escaping (Email) async throws -> Void) {
    self.send = send
  }
}

public struct Email {
  public var to: String
  public var from: String
  public var replyTo: String?
  public var subject: String
  public var html: String

  public init(to: String, from: String, replyTo: String? = nil, subject: String, html: String) {
    self.to = to
    self.from = from
    self.replyTo = replyTo
    self.subject = subject
    self.html = html
  }
}

// extensions

public extension Client {
  struct Error: Swift.Error {
    public let statusCode: Int
    public let errorCode: Int
    public let message: String
  }

  static func live(apiKey: String) -> Self {
    Client(send: { email in
      let (data, urlResponse) = try await HTTP.postJson(
        ApiEmail(email: email),
        to: "https://api.postmarkapp.com/email",
        headers: [
          "Accept": "application/json",
          "X-Postmark-Server-Token": apiKey,
        ]
      )

      if urlResponse.statusCode == 200 {
        return
      }

      let response: ApiResponse
      do {
        response = try JSONDecoder().decode(ApiResponse.self, from: data)
      } catch {
        throw Error(
          statusCode: urlResponse.statusCode,
          errorCode: -1,
          message: "Error decoding Postmark response: \(error)"
        )
      }
      throw Error(
        statusCode: urlResponse.statusCode,
        errorCode: response.ErrorCode,
        message: response.Message
      )
    })
  }
}

public extension Client {
  static var mock: Self = .init(send: { _ in })
}

// api types

struct ApiEmail: Encodable {
  let From: String
  let To: String
  let Subject: String
  let HtmlBody: String
  let ReplyTo: String?
  let TrackOpens: Bool

  init(email: Email) {
    self.From = email.from
    self.To = email.to
    self.Subject = email.subject
    self.HtmlBody = email.html
    self.ReplyTo = email.replyTo
    self.TrackOpens = true
  }
}

struct ApiResponse: Decodable {
  let ErrorCode: Int
  let Message: String
}
