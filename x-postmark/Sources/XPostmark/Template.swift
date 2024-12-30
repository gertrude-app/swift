import Foundation
import XHttp

public struct TemplateEmail: Equatable {
  public var to: String
  public var from: String
  public var templateAlias: String
  public var templateModel: [String: String] = [:]
  public var messageStream: String?

  public init(
    to: String,
    from: String,
    templateAlias: String,
    templateModel: [String: String] = [:],
    messageStream: String? = nil
  ) {
    self.to = to
    self.from = from
    self.templateAlias = templateAlias
    self.templateModel = templateModel
    self.messageStream = messageStream
  }
}

@Sendable func _sendTemplateEmailBatch(
  _ emails: [TemplateEmail],
  _ apiKey: String
) async -> Result<[Result<Void, Client.BatchEmail.Error>], Client.Error> {
  if emails.count >= 500 {
    return .failure(.init(
      statusCode: -3,
      errorCode: -3,
      message: "Batched chunking not implemented, size must be less than 500"
    ))
  }
  do {
    let (data, urlResponse) = try await HTTP.postJson(
      Batch(Messages: emails.map(ApiTemplateEmail.init)),
      to: "https://api.postmarkapp.com/email/batchWithTemplates",
      headers: [
        "Accept": "application/json",
        "X-Postmark-Server-Token": apiKey,
      ]
    )
    do {
      if urlResponse.statusCode != 200 {
        let decoded = try JSONDecoder().decode(ApiResponse.self, from: data)
        return .failure(Client.Error(
          statusCode: urlResponse.statusCode,
          errorCode: decoded.ErrorCode,
          message: decoded.Message
        ))
      } else {
        let responses = try JSONDecoder().decode([BatchEmailResponse].self, from: data)
        return .success(responses.map { response in
          if response.ErrorCode == 0 {
            return .success(())
          } else {
            return .failure(.init(
              errorCode: response.ErrorCode,
              message: response.Message
            ))
          }
        })
      }
    } catch {
      let body = String(decoding: data, as: UTF8.self)
      return .failure(Client.Error(
        statusCode: urlResponse.statusCode,
        errorCode: -4,
        message: "Error decoding Postmark batch response: \(error), body: \(body)"
      ))
    }
  } catch {
    return .failure(Client.Error(
      statusCode: -5,
      errorCode: -5,
      message: "Error sending Postmark batch emails: \(error)"
    ))
  }
}

struct Batch: Encodable {
  let Messages: [ApiTemplateEmail]
}

struct BatchEmailResponse: Decodable {
  let ErrorCode: Int
  let Message: String
}

struct ApiTemplateEmail: Encodable {
  let To: String
  let From: String
  let TemplateAlias: String
  let TemplateModel: [String: String]
  let MessageStream: String?
}

extension ApiTemplateEmail {
  init(email: TemplateEmail) {
    self.To = email.to
    self.From = email.from
    self.TemplateAlias = email.templateAlias
    self.TemplateModel = email.templateModel
    self.MessageStream = email.messageStream
  }
}
