public protocol TsType {
  static var ts: String { get }
}

public protocol TsInputType: TsType {}
public protocol TsOutputType: TsType {}

public typealias TsPairInput = TsType & Codable & Equatable

public protocol TsPairOutput: PairOutput, TsType {
  static var ts: String { get }
}

public protocol TsPair: Pair where Input: TsType, Output: TsPairOutput {
  static var id: String { get }
  static var auth: ClientAuth { get }
}

public protocol TsPrimitive {
  static var tsPrimitiveType: String { get }
}

extension String: TsPrimitive {
  public static var tsPrimitiveType: String { "string" }
}

extension String: TsType {
  public static var ts: String { "export type __self__ = \(tsPrimitiveType)" }
}

extension String: TsPairOutput {}

extension Array: TsType where Element: TsPrimitive {
  public static var ts: String {
    "export type __self__ = \(Element.tsPrimitiveType)[]"
  }
}
