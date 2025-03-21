import Foundation

public enum IpProtocol: Equatable, CustomStringConvertible, Codable, Sendable {
  case tcp(Int32)
  case udp(Int32)
  case other(Int32)

  public var number: Int32 {
    switch self {
    case .tcp(let num):
      num
    case .udp(let num):
      num
    case .other(let num):
      num
    }
  }

  public var int: Int {
    Int(self.number)
  }

  public var isTcp: Bool {
    switch self {
    case .tcp:
      true
    default:
      false
    }
  }

  public var isUdp: Bool {
    switch self {
    case .udp:
      true
    default:
      false
    }
  }

  public var isOther: Bool {
    switch self {
    case .other:
      true
    default:
      false
    }
  }

  public var shortDescription: String {
    switch self {
    case .tcp:
      "TCP"
    case .udp:
      "UDP"
    case .other:
      "OTHER"
    }
  }

  public var description: String {
    switch self {
    case .tcp:
      "TCP"
    case .udp:
      "UDP"
    case .other(let number):
      "OTHER(\(number))"
    }
  }

  public init(_ int32: Int32) {
    switch int32 {
    case Int32(IPPROTO_TCP):
      self = .tcp(int32)
    case Int32(IPPROTO_UDP):
      self = .udp(int32)
    default:
      self = .other(int32)
    }
  }

  public init?(_ string: String) {
    guard let int32 = Int32(string) else {
      return nil
    }
    self = .init(int32)
  }
}

public extension IpProtocol {
  enum Kind: String, Equatable, Sendable, Codable {
    case tcp
    case udp
    case other
  }

  var kind: Kind {
    switch self {
    case .tcp:
      .tcp
    case .udp:
      .udp
    case .other:
      .other
    }
  }
}
