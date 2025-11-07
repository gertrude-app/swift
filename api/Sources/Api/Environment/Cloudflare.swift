import Dependencies
import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct CloudflareClient: Sendable {
  var verifyTurnstileToken: @Sendable (_ token: String) async -> TurnstileResult
}

extension CloudflareClient: DependencyKey {
  static var liveValue: CloudflareClient {
    .init { token in
      do {
        let secret = get(dependency: \.env.cloudflareSecret)
        let response = try await HTTP.postFormUrlencoded(
          ["secret": secret, "response": token],
          to: "https://challenges.cloudflare.com/turnstile/v0/siteverify",
          decoding: VerifyResponse.self,
        )
        if response.success {
          return .success
        } else {
          return .failure(errorCodes: response.errorCodes, messages: response.messages)
        }
      } catch {
        return .error(error)
      }
    }
  }
}

extension CloudflareClient: TestDependencyKey {
  static var testValue: CloudflareClient {
    .init(verifyTurnstileToken: unimplemented(
      "CloudflareClient.verifyTurnstileToken()",
      placeholder: .success,
    ))
  }
}

extension DependencyValues {
  var cloudflare: CloudflareClient {
    get { self[CloudflareClient.self] }
    set { self[CloudflareClient.self] = newValue }
  }
}

enum TurnstileResult {
  case success
  case failure(errorCodes: [String], messages: [String]?)
  case error(any Error)
}

struct VerifyResponse: Decodable {
  var success: Bool
  var hostname: String?
  var messages: [String]?
  var errorCodes: [String]

  enum CodingKeys: String, CodingKey {
    case success
    case hostname
    case messages
    case errorCodes = "error-codes"
  }
}
