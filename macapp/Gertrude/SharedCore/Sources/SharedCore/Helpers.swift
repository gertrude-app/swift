import Foundation

precedencegroup ForwardApplication {
  associativity: left
}

infix operator |>: ForwardApplication

public func |> <A, B>(_ a: A, _ f: @escaping (A) -> B) -> B {
  f(a)
}

public let conciseTimeFormatter = { () -> DateFormatter in
  var formatter = DateFormatter()
  formatter.dateFormat = "hh:mm:ssa"
  return formatter
}()

public let isoDateFormatter = ISO8601DateFormatter()

public func afterDelayOf(seconds: Double, work: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
}

public func afterDelayOf(seconds: Int, work: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + Double(seconds), execute: work)
}

public extension Bundle {
  var version: String {
    (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "(unknown)"
  }
}
