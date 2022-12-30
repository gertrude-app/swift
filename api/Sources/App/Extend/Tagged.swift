import Foundation
import Tagged
import TypescriptPairQL

extension Tagged: TypescriptPrimitive where RawValue == UUID {
  public static var tsPrimitiveType: String {
    "UUID"
  }
}
