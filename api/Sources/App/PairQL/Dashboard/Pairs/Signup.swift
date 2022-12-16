import Foundation
import Shared
import TypescriptPairQL

struct Signup: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var email: String
    var password: String
    var signupToken: String?
  }

  struct Output: TypescriptPairOutput {
    let url: String?
  }
}

struct AllowingSignups: TypescriptPair {
  static var auth: ClientAuth = .none
}
