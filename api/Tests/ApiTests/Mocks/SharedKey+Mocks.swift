import DuetMock
import Shared

extension Key: Mock {
  public static var mock: Key {
    .domain(domain: .init("foo.com")!, scope: .mock)
  }

  public static var empty: Key {
    .ipAddress(ip: .init("0.0.0.0")!, scope: .empty)
  }

  public static var random: Key {
    switch Int.random(in: 1 ... 6) {
    case 1:
      return .domain(domain: .init("foo.com")!, scope: .random)
    case 2:
      return .anySubdomain(domain: .init("foo.com")!, scope: .random)
    case 3:
      return .skeleton(scope: .random)
    case 4:
      return .domainRegex(pattern: .init("foo-*.com")!, scope: .random)
    case 5:
      return .path(path: .init("foo.com/bar")!, scope: .random)
    default:
      return .ipAddress(ip: .init("1.2.3.4")!, scope: .random)
    }
  }
}
