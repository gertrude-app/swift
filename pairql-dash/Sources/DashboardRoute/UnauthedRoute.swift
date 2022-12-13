import Foundation
import TypescriptPairQL

public enum UnauthedRoute: PairRoute {
  case tsCodegen
  public static let router = OneOf {
    Route(/Self.tsCodegen) {
      Operation(TsCodegen.self)
    }
  }
}

public struct TsCodegen: Pair, TypescriptPair {
  public static var auth: ClientAuth = .none
  public typealias Output = [String: String]
}
