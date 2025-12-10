import Dependencies
import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct TwilioSmsClient: Sendable {
  var send: @Sendable (_ text: Text) async throws -> Void
}

struct TwilioError: Error, CustomStringConvertible {
  let statusCode: Int
  let body: String

  var description: String {
    "Twilio error (status \(self.statusCode)): \(self.body)"
  }
}

extension TwilioSmsClient: DependencyKey {
  static var liveValue: TwilioSmsClient {
    @Dependency(\.env.twilio) var env
    return .init { text in
      let (sid, auth, from) = (env.accountSid, env.authToken, env.fromPhone)
      let url = "https://\(sid):\(auth)@api.twilio.com/2010-04-01/Accounts/\(sid)/Messages.json"

      var request = URLRequest(url: URL(string: url)!)
      request.httpMethod = "POST"
      request.httpBody = "From=\(from)&To=\(text.to)&Body=\(text.message)".data(using: .utf8)

      let (data, response) = try await XHttp.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw TwilioError(statusCode: 0, body: "Invalid response type")
      }

      guard (200 ... 299).contains(httpResponse.statusCode) else {
        let bodyString = String(data: data, encoding: .utf8) ?? "<decode err>"
        throw TwilioError(statusCode: httpResponse.statusCode, body: bodyString)
      }
    }
  }
}

extension TwilioSmsClient {
  static let mock = TwilioSmsClient(send: { _ in })
}

extension DependencyValues {
  var twilio: TwilioSmsClient {
    get { self[TwilioSmsClient.self] }
    set { self[TwilioSmsClient.self] = newValue }
  }
}

extension TwilioSmsClient: TestDependencyKey {
  static var testValue: TwilioSmsClient {
    .init(send: unimplemented("TwilioSmsClient.send(_:)"))
  }
}
