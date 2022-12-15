import Foundation
import TypescriptPairQL

public enum UnauthedRoute: PairRoute {
  case tsCodegen
  case signup(Signup.Input)

  public static let router = OneOf {
    Route(/Self.tsCodegen) {
      Operation(TsCodegen.self)
    }
    Route(/Self.signup) {
      Operation(Signup.self)
      Body(.json(Signup.Input.self))
    }
  }
}

public struct TsCodegen: Pair, TypescriptPair {
  public static var auth: ClientAuth = .none
  public typealias Output = [String: String]
}
