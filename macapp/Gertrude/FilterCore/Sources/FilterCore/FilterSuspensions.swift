import Foundation
import Gertie
import XCore

public class FilterSuspensions {
  private var map: [uid_t: FilterSuspension] = [:]

  public init() {}

  public func set(_ suspension: FilterSuspension, userId: uid_t) {
    map[userId] = suspension
  }

  public func get(userId: uid_t) -> FilterSuspension? {
    guard let suspension = map[userId] else {
      return nil
    }
    if !suspension.isActive {
      revoke(userId: userId)
      return nil
    }
    return suspension
  }

  public func revoke(userId: uid_t) {
    map[userId] = nil
  }
}

public extension FilterSuspensions {
  var debugData: String {
    guard map.count > 0 else {
      return "{}"
    }
    return (try? JSON.encode(map)) ?? "{}"
  }
}
