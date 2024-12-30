import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct Email: Sendable {
  public var to: String
  public var from: String
  public var replyTo: String?
  public var subject: String

  /// invariant: one of these is always set
  public private(set) var htmlBody: String?
  public private(set) var textBody: String?

  public var body: String {
    self.htmlBody ?? self.textBody!
  }

  public init(
    to: String,
    from: String,
    replyTo: String? = nil,
    subject: String,
    textBody: String,
    htmlBody: String? = nil
  ) {
    self.to = to
    self.from = from
    self.replyTo = replyTo
    self.subject = subject
    self.textBody = textBody
    self.htmlBody = htmlBody
  }

  public init(
    to: String,
    from: String,
    replyTo: String? = nil,
    subject: String,
    htmlBody: String,
    textBody: String? = nil
  ) {
    self.to = to
    self.from = from
    self.replyTo = replyTo
    self.subject = subject
    self.htmlBody = htmlBody
    self.textBody = textBody
  }
}

enum SingleEmail {
  case email(Email)
  case template(TemplateEmail)
}

@Sendable func sendSingle(
  _ email: SingleEmail,
  _ apiKey: String
) async -> Result<Void, Client.Error> {
  do {
    let headers = [
      "Accept": "application/json",
      "X-Postmark-Server-Token": apiKey,
    ]
    let data: Data
    let urlResponse: HTTPURLResponse
    switch email {
    case .email(let email):
      (data, urlResponse) = try await HTTP.postJson(
        ApiEmail(email: email),
        to: "https://api.postmarkapp.com/email",
        headers: headers
      )
    case .template(let email):
      (data, urlResponse) = try await HTTP.postJson(
        ApiTemplateEmail(email: email),
        to: "https://api.postmarkapp.com/email/withTemplate",
        headers: headers
      )
    }
    if urlResponse.statusCode == 200 {
      return .success(())
    }

    do {
      let decoded = try JSONDecoder().decode(ApiResponse.self, from: data)
      return .failure(Client.Error(
        statusCode: urlResponse.statusCode,
        errorCode: decoded.ErrorCode,
        message: decoded.Message
      ))
    } catch {
      let body = String(decoding: data, as: UTF8.self)
      return .failure(Client.Error(
        statusCode: urlResponse.statusCode,
        errorCode: -1,
        message: "Error decoding Postmark response: \(error), body: \(body)"
      ))
    }
  } catch {
    return .failure(Client.Error(
      statusCode: -2,
      errorCode: -2,
      message: "Error sending Postmark email: \(error)"
    ))
  }
}

struct ApiEmail: Encodable {
  let From: String
  let To: String
  let Subject: String
  let HtmlBody: String?
  let TextBody: String?
  let ReplyTo: String?
  let TrackOpens: Bool

  init(email: Email) {
    self.From = email.from
    self.To = email.to
    self.Subject = email.subject
    self.HtmlBody = email.htmlBody
    self.TextBody = email.textBody
    self.ReplyTo = email.replyTo
    self.TrackOpens = true
  }
}
