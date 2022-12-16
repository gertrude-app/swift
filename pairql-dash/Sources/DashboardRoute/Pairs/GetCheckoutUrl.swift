import Foundation
import Shared
import TypescriptPairQL

public struct GetCheckoutUrl: TypescriptPair {
  public static var auth: ClientAuth = .admin

  public struct Input: TypescriptPairInput {
    public var adminId: UUID

    public init(adminId: UUID) {
      self.adminId = adminId
    }
  }

  public struct Output: TypescriptPairOutput {
    public let url: String?

    public init(url: String? = nil) {
      self.url = url
    }
  }
}
