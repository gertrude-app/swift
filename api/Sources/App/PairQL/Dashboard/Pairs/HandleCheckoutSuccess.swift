import Foundation
import Shared
import TypescriptPairQL

struct HandleCheckoutSuccess: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var stripeCheckoutSessionid: String
  }

  struct Output: TypescriptPairOutput {
    var token: UUID
    var adminId: UUID
  }
}
