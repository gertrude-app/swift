import Foundation

public typealias RootApp = (bundleId: String?, displayName: String?)

public protocol RootAppQuery {
  func get(from token: Data?) -> RootApp
}

public struct NullRootAppQuery: RootAppQuery {
  public func get(from token: Data?) -> RootApp {
    (nil, nil)
  }

  public init() {}
}
