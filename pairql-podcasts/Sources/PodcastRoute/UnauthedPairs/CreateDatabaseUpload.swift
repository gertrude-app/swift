import Foundation
import PairQL

/// in use: v1.0.0 - present
public struct CreateDatabaseUpload: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public let installId: UUID

    public init(installId: UUID) {
      self.installId = installId
    }
  }

  public struct Output: PairOutput {
    public let uploadUrl: URL

    public init(uploadUrl: URL) {
      self.uploadUrl = uploadUrl
    }
  }
}
