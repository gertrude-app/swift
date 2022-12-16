import TypescriptPairQL

struct JoinWaitlist: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var email: String
  }
}
