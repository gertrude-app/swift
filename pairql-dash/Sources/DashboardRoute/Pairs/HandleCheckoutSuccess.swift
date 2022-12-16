import Foundation
import Shared
import TypescriptPairQL

public struct HandleCheckoutSuccess: TypescriptPair {
  public static var auth: ClientAuth = .none

  public struct Input: TypescriptPairInput {
    public var stripeCheckoutSessionid: String

    public init(stripeCheckoutSessionid: String) {
      self.stripeCheckoutSessionid = stripeCheckoutSessionid
    }
  }

  public struct Output: TypescriptPairOutput {
    public var token: UUID
    public var adminId: UUID

    public init(token: UUID, adminId: UUID) {
      self.token = token
      self.adminId = adminId
    }
  }
}
