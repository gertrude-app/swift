import Foundation
import Shared
import TypescriptPairQL

public struct JoinWaitlist: TypescriptPair {
  public static var auth: ClientAuth = .none

  public struct Input: TypescriptPairInput {
    public var email: String

    public init(email: String) {
      self.email = email
    }
  }
}
