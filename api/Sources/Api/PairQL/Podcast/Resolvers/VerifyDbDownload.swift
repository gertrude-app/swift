import Dependencies
import Foundation
import PodcastRoute

extension VerifyDbDownload: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    .failure
  }
}
