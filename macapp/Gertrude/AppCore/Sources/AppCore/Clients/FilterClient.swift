import Combine
import Foundation
import SharedCore

struct FilterClient {
  var getCurrentExemptUserIds: () -> AnyPublisher<Set<uid_t>, Never>
  var sendExemptUserIds: (Set<uid_t>) -> AnyPublisher<Void, Set<uid_t>>
}

extension FilterClient {
  static let live = Self {
    Future { promise in
      SendToFilter.getCurrentExemptUserIds { ids in
        promise(.success(ids))
      }
    }.eraseToAnyPublisher()
  } sendExemptUserIds: { ids in
    if ids.isEmpty {
      SendToFilter.removeAllExemptUsers()
    } else {
      SendToFilter.exemptUserIds(String(ids.map(String.init).joined(separator: ",")))
    }
    return Future { promise in
      afterDelayOf(seconds: 1.5) {
        SendToFilter.getCurrentExemptUserIds { updated in
          if updated != ids {
            promise(.failure(updated))
          } else {
            promise(.success(()))
          }
        }
      }
    }
    .eraseToAnyPublisher()
  }
}

extension FilterClient {
  static let noop = Self {
    Empty<Set<uid_t>, Never>().eraseToAnyPublisher()
  } sendExemptUserIds: { _ in
    Empty<Void, Set<uid_t>>().eraseToAnyPublisher()
  }
}

extension Set: Error where Element == uid_t {}
