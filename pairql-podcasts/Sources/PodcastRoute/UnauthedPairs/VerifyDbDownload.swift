import Foundation
import PairQL

public struct VerifyDbDownload: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public let installId: UUID
    public let downloadUrl: String

    public init(installId: UUID, downloadUrl: String) {
      self.installId = installId
      self.downloadUrl = downloadUrl
    }
  }

  public typealias Output = SuccessOutput
}
