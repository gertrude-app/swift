import Foundation

public struct FilterUserTypes: Codable, Sendable, Equatable {
  public var exempt: [uid_t]
  public var protected: [uid_t]

  public init(exempt: [uid_t], protected: [uid_t]) {
    self.exempt = exempt
    self.protected = protected
  }
}

// to/from transport is because i don't want to make a "breaking" change
// to the filter<->app xpc contract at the moment, when i do, i should
// remove this, and have the filter talk directly with this type coded as json
public extension FilterUserTypes {
  var transport: [uid_t] {
    var joined = self.exempt
    for userId in self.protected {
      // uid_t is a UInt32, so we can't use negative numbers
      // +1 mil is our sentinal for protected users
      joined.append(userId + 1_000_000)
    }
    return joined
  }

  init(transport: [uid_t]) {
    var exempt = [uid_t]()
    var protected = [uid_t]()
    for userId in transport {
      if userId > 1_000_000 {
        protected.append(userId - 1_000_000)
      } else {
        exempt.append(userId)
      }
    }
    self.init(exempt: exempt, protected: protected)
  }
}
