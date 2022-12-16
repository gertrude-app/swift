import Foundation
import TypescriptPairQL

public struct DeleteUser: TypescriptPair {
  public static var auth: ClientAuth = .admin
  public typealias Input = UUID
}
