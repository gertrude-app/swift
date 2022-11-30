import Foundation

public enum IpProtocol: Equatable, CustomStringConvertible, Codable {
  case tcp(Int32)
  case udp(Int32)
  case other(Int32)

  public var number: Int32 {
    switch self {
    case .tcp(let num):
      return num
    case .udp(let num):
      return num
    case .other(let num):
      return num
    }
  }

  public var int: Int {
    Int(number)
  }

  public var isTcp: Bool {
    switch self {
    case .tcp:
      return true
    default:
      return false
    }
  }

  public var isUdp: Bool {
    switch self {
    case .udp:
      return true
    default:
      return false
    }
  }

  public var isOther: Bool {
    switch self {
    case .other:
      return true
    default:
      return false
    }
  }

  public var shortDescription: String {
    switch self {
    case .tcp:
      return "TCP"
    case .udp:
      return "UDP"
    case .other:
      return "OTHER"
    }
  }

  public var description: String {
    switch self {
    case .tcp:
      return "TCP"
    case .udp:
      return "UDP"
    case .other(let number):
      return "OTHER(\(number))"
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
