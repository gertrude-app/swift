import Foundation
import PairQL

public struct VerifyPromoCode: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public let installId: UUID
    public let code: String

    public init(installId: UUID, code: String) {
      self.installId = installId
      self.code = code
    }
  }

  public typealias Output = SuccessOutput
}
