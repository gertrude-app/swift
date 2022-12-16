import Foundation
import Shared
import TypescriptPairQL

public struct Signup: TypescriptPair {
  public static var auth: ClientAuth = .none

  public struct Input: TypescriptPairInput {
    public var email: String
    public var password: String
    public var signupToken: String?

    public init(email: String, password: String, signupToken: String? = nil) {
      self.email = email
      self.password = password
      self.signupToken = signupToken
    }
  }

  public struct Output: TypescriptPairOutput {
    public let url: String?

    public init(url: String? = nil) {
      self.url = url
    }
  }
}

public struct AllowingSignups: TypescriptPair {
  public static var auth: ClientAuth = .none
}
