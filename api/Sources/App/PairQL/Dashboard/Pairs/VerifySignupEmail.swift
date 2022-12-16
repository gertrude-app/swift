import Foundation
import TypescriptPairQL

struct VerifySignupEmail: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    let token: UUID
  }

  struct Output: TypescriptPairOutput {
    let adminId: UUID
  }
}
