import Foundation
import Tagged
import TypescriptPairQL

extension Tagged: TypescriptPrimitive where RawValue == UUID {
  public static var tsPrimitiveType: String { "UUID" }
}

extension Tagged: PairInput where RawValue == UUID {}
extension Tagged: TypescriptRepresentable where RawValue == UUID {}
