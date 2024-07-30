import Foundation

// linux
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct TwilioSmsClient: Sendable {
  var send = send(_:)
}

@Sendable private func send(_ text: Text) {
  let (sid, auth, from) = (Env.TWILIO_ACCOUNT_SID, Env.TWILIO_AUTH_TOKEN, Env.TWILIO_FROM_PHONE)
  let url = "https://\(sid):\(auth)@api.twilio.com/2010-04-01/Accounts/\(sid)/Messages.json"

  var request = URLRequest(url: URL(string: url)!)
  request.httpMethod = "POST"
  request.httpBody = "From=\(from)&To=\(text.to)&Body=\(text.message)".data(using: .utf8)

  URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
      Current.logger.warning("Error sending twilio sms: \(error.localizedDescription)")
      return
    }
  }
  .resume()
}

extension TwilioSmsClient {
  static let mock = TwilioSmsClient(send: { _ in })
}
