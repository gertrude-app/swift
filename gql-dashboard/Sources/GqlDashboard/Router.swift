import Foundation
import URLRouting

@_exported import GertieQL

public enum DashboardRoute: Equatable {
  case tsCodegen(TsCodegen.Input)

  // NEXT: how do i get ALL ts pairs in a type-safe compiler-checked way
}

public extension DashboardRoute {
  static let router = OneOf {
    Route(.case(Self.tsCodegen)) {
      Path { TsCodegen.id }
      Body(.json([String].self))
    }
  }
}

public struct TsCodegen: Pair, TypescriptPair {
  public static var id: String { "tsCodegen" }
  public static var auth: ClientAuth = .none
  public typealias Input = [String]
  public typealias Output = String
}
