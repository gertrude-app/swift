import Dependencies
import Foundation
import PodcastRoute

extension VerifyPromoCode: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let code = context.env.get("PODCAST_FREE_SUB_CODE"), !code.isEmpty else {
      return .failure
    }
    return input.code == code ? .success : .failure
  }
}
