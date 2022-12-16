import Foundation
import Shared
import TypescriptPairQL

public struct VerifySignupEmail: TypescriptPair {
  public static var auth: ClientAuth = .none

  public struct Input: TypescriptPairInput {
    public let token: UUID

    public init(token: UUID) {
      self.token = token
    }
  }

  public struct Output: TypescriptPairOutput {
    public let adminId: UUID

    public init(adminId: UUID) {
      self.adminId = adminId
    }
  }
}
