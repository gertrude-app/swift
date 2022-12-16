import Foundation
import Shared
import TypescriptPairQL

struct GetCheckoutUrl: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    var adminId: UUID
  }

  struct Output: TypescriptPairOutput {
    let url: String?
  }
}
